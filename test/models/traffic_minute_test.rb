require "test_helper"

class TrafficMinuteTest < ActiveSupport::TestCase
  def row(minute: "2026-11-20T01:46:00Z", host: "realcalc.lyndbergh.net", **counts)
    { "host" => host, "minute" => minute, "requests" => 2, "errors_4xx" => 1, "errors_5xx" => 0, "total_ms" => 20.0, "max_ms" => 15.0 }
      .merge(counts.transform_keys(&:to_s))
  end

  test "stores rows for known sites and skips unknown hosts and bad minutes" do
    stored = TrafficMinute.record!([ row, row(host: "evil.example.com"), row(minute: "not a time") ])
    assert_equal 1, stored
    minute = TrafficMinute.sole
    assert_equal [ "real-calc", Time.utc(2026, 11, 20, 1, 46) ], [ minute.site_slug, minute.minute ]
  end

  test "a minute sent in two batches adds up, keeping the larger max" do
    TrafficMinute.record!([ row ])
    TrafficMinute.record!([ row("requests" => 3, "errors_5xx" => 1, "total_ms" => 30.0, "max_ms" => 40.0) ])
    minute = TrafficMinute.sole
    assert_equal [ 5, 2, 1, 50.0, 40.0 ], [ minute.requests, minute.errors_4xx, minute.errors_5xx, minute.total_ms, minute.max_ms ]
  end

  test "totals and an hourly series with empty hours filled in" do
    travel_to Time.utc(2026, 11, 20, 3, 30) do
      TrafficMinute.record!([ row(minute: "2026-11-20T01:10:00Z"), row(minute: "2026-11-20T03:05:00Z", "requests" => 4, "total_ms" => 40.0) ])
      scope = TrafficMinute.where(site_slug: "real-calc")
      assert_equal({ requests: 6, errors_4xx: 2, errors_5xx: 0, avg_ms: 10, max_ms: 15 }, scope.totals)
      series = scope.series(since: 3.hours.ago, step: 1.hour)
      assert_equal [ 0, 2, 0, 4 ], series.map(&:last)
      assert_equal Time.utc(2026, 11, 20, 0), series.first.first
    end
  end

  test "prune drops minutes older than 90 days" do
    TrafficMinute.create!(site_slug: "real-calc", minute: 91.days.ago, requests: 1)
    TrafficMinute.create!(site_slug: "real-calc", minute: 1.day.ago, requests: 1)
    assert_equal 1, TrafficMinute.prune
    assert_equal 1, TrafficMinute.count
  end
end
