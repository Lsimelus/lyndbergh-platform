require "net/http"

# One health check of a site: up or down, and why.
class Check < ApplicationRecord
  TIMEOUT = 10

  scope :recent, -> { order(created_at: :desc) }

  # Requests the site's health URL and records the result. `http` is swappable in tests.
  def self.run(site, http: method(:fetch))
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = http.call(URI(site.check_url))
    latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

    status = response.code.to_i
    problems = []
    problems << "HTTP #{status}" unless status.between?(200, 399)
    problems << "expected JSON" if site.expect == "json" && !json?(response.body)

    create!(site_slug: site.slug, ok: problems.empty?, http_status: status, latency_ms: latency_ms, error: problems.join("; ").presence)
  rescue StandardError => e
    create!(site_slug: site.slug, ok: false, error: "#{e.class}: #{e.message}".truncate(500))
  end

  def self.fetch(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.get(uri.request_uri, "User-Agent" => "lyndbergh-platform-monitor")
    end
  end

  def self.json?(body)
    JSON.parse(body.to_s)
    true
  rescue JSON::ParserError
    false
  end

  def self.prune(older_than: 30.days.ago) = where(created_at: ...older_than).delete_all

  # Share of checks that passed since `since`, as a percentage, or nil with no checks.
  def self.uptime(since: 24.hours.ago)
    scope = where(created_at: since..)
    total = scope.count
    total.zero? ? nil : (scope.where(ok: true).count * 100.0 / total).round(1)
  end
end
