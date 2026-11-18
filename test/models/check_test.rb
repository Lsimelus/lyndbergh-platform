require "test_helper"

class CheckTest < ActiveSupport::TestCase
  REAL_CALC = Site.find("real-calc")
  PORTFOLIO = Site.find("portfolio")

  test "a 200 with JSON is up" do
    check = Check.run(REAL_CALC, http: respond_with(200, { data: { status: "healthy" } }))

    assert check.ok?
    assert_equal 200, check.http_status
    assert_nil check.error
  end

  test "an API answering with HTML is down" do
    check = Check.run(REAL_CALC, http: respond_with(200, "<!DOCTYPE html>"))

    assert_not check.ok?
    assert_equal "expected JSON", check.error
  end

  test "an error status is down" do
    check = Check.run(REAL_CALC, http: respond_with(503, "<html>Service Unavailable</html>"))

    assert_not check.ok?
    assert_equal "HTTP 503; expected JSON", check.error
  end

  test "a site without expectations only needs a 2xx or 3xx" do
    assert Check.run(PORTFOLIO, http: respond_with(200, "<html></html>")).ok?
  end

  test "network errors are recorded as down" do
    check = Check.run(PORTFOLIO, http: ->(_uri) { raise Net::OpenTimeout, "execution expired" })

    assert_not check.ok?
    assert_equal "Net::OpenTimeout: execution expired", check.error
  end

  test "prune drops checks older than 30 days" do
    Check.create!(site_slug: "portfolio", ok: true, created_at: 31.days.ago)
    fresh = Check.create!(site_slug: "portfolio", ok: true)
    Check.prune

    assert_equal [ fresh.id ], Check.pluck(:id)
  end

  test "uptime is the share of passing checks in the window" do
    Check.create!(site_slug: "portfolio", ok: true)
    Check.create!(site_slug: "portfolio", ok: false)
    Check.create!(site_slug: "portfolio", ok: true, created_at: 2.days.ago)

    assert_equal 50.0, Check.where(site_slug: "portfolio").uptime
  end
end
