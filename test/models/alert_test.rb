require "test_helper"

class AlertTest < ActiveSupport::TestCase
  SITE = Site.find("portfolio")

  setup { @sent = [] }
  teardown { ENV.delete("ALERT_URL") }

  def recorder = ->(url, body, tag) { @sent << [ url, body, tag ] }
  def check(ok, error = nil) = Check.new(site_slug: SITE.slug, ok: ok, error: error)

  test "alerts when a site goes down and when it comes back" do
    ENV["ALERT_URL"] = "https://ntfy.sh/topic"

    Alert.status_changed(SITE, previous: check(true), current: check(false, "HTTP 503"), post: recorder)
    Alert.status_changed(SITE, previous: check(false), current: check(true), post: recorder)

    assert_equal [ [ "https://ntfy.sh/topic", "Portfolio is down: HTTP 503", "rotating_light" ],
                   [ "https://ntfy.sh/topic", "Portfolio is back up", "white_check_mark" ] ], @sent
  end

  test "stays quiet while nothing changes, and on a site's first check" do
    Alert.status_changed(SITE, previous: check(false), current: check(false), post: recorder)
    Alert.status_changed(SITE, previous: check(true), current: check(true), post: recorder)
    Alert.status_changed(SITE, previous: nil, current: check(false), post: recorder)

    assert_empty @sent
  end

  test "sending is a no-op without a URL and never raises" do
    assert_nil Alert.post(nil, "x", nil)
    assert_nil Alert.post("http://127.0.0.1:9/unreachable", "x", nil)
  end
end
