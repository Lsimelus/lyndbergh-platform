# Traffic per site per minute, sent every 5 minutes by script/traffic-collector on the server, which reads
# kamal-proxy's request log. Only counts are kept: no IPs, user agents or paths.
class TrafficMinute < ApplicationRecord
  KEEP = 90.days
  MAX_ROWS = 5_000
  COUNTS = %i[requests errors_4xx errors_5xx].freeze

  # rows: [{ "host" => "realcalc.lyndbergh.net", "minute" => ISO 8601, "requests", "errors_4xx", "errors_5xx",
  # "total_ms", "max_ms" }]. A minute can arrive in two batches, so counts add up; hosts that aren't a site are skipped.
  # Returns how many rows were stored.
  def self.record!(rows)
    by_host = Site.all.index_by { |site| URI(site.url).host }
    records = Array(rows).first(MAX_ROWS).filter_map do |row|
      site = by_host[row["host"].to_s]
      minute = Time.iso8601(row["minute"].to_s).utc.beginning_of_minute rescue nil
      next unless site && minute

      { site_slug: site.slug, minute: minute, total_ms: row["total_ms"].to_f.clamp(0, Float::MAX),
        max_ms: row["max_ms"].to_f.clamp(0, Float::MAX), **COUNTS.to_h { |key| [ key, row[key.to_s].to_i.clamp(0, 10_000_000) ] } }
    end
    return 0 if records.empty?

    upsert_all(records, unique_by: %i[site_slug minute], on_duplicate: Arel.sql(
      "requests = traffic_minutes.requests + excluded.requests, errors_4xx = traffic_minutes.errors_4xx + excluded.errors_4xx, " \
      "errors_5xx = traffic_minutes.errors_5xx + excluded.errors_5xx, total_ms = traffic_minutes.total_ms + excluded.total_ms, " \
      "max_ms = MAX(traffic_minutes.max_ms, excluded.max_ms)"))
    records.size
  end

  def self.prune = where(minute: ...KEEP.ago).delete_all

  # { requests:, errors_4xx:, errors_5xx:, avg_ms:, max_ms: } over the scope.
  def self.totals
    requests, e4, e5, total, max = pick(Arel.sql("COALESCE(SUM(requests), 0)"), Arel.sql("COALESCE(SUM(errors_4xx), 0)"),
                                        Arel.sql("COALESCE(SUM(errors_5xx), 0)"), Arel.sql("COALESCE(SUM(total_ms), 0)"),
                                        Arel.sql("COALESCE(MAX(max_ms), 0)"))
    { requests: requests, errors_4xx: e4, errors_5xx: e5, avg_ms: requests.positive? ? (total / requests).round : nil, max_ms: max.round }
  end

  # Requests per bucket (hour or day), oldest first, with empty buckets as 0: [[Time, count], ...].
  def self.series(since:, step:)
    format = step == 1.day ? "%Y-%m-%d 00:00:00" : "%Y-%m-%d %H:00:00"
    counts = where(minute: since..).group(Arel.sql("strftime('#{format}', minute)")).sum(:requests)
    start = step == 1.day ? since.utc.beginning_of_day : since.utc.beginning_of_hour
    (0...((Time.current - start) / step).ceil).map do |i|
      at = start + (i * step)
      [ at, counts[at.strftime(format)].to_i ]
    end
  end
end
