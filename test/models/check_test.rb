require "test_helper"

class CheckTest < ActiveSupport::TestCase
  REAL_CALC = Site.find("real-calc")
  PORTFOLIO = Site.find("portfolio")

  test "a healthy response that matches the contract is up" do
    body = { data: { status: "healthy", database: "connected", timestamp: "2026-11-18T12:00:00.000000" }, meta: nil, error: nil }
    check = Check.run(REAL_CALC, http: respond_with(200, body))

    assert check.ok?
    assert_equal 200, check.http_status
    assert_nil check.error
  end

  test "a 200 that breaks the contract is down" do
    check = Check.run(REAL_CALC, http: respond_with(200, { status: "ok" }))

    assert_not check.ok?
    assert_match(/contract:/, check.error)
  end

  test "a documented 503 is down but not a contract violation" do
    body = { data: nil, meta: nil, error: { message: "Service unavailable", code: "http_503" } }
    check = Check.run(REAL_CALC, http: respond_with(503, body))

    assert_not check.ok?
    assert_equal "HTTP 503", check.error
  end

  test "an undocumented status is a contract violation" do
    check = Check.run(REAL_CALC, http: respond_with(502, "<html>Bad gateway</html>"))

    assert_equal "HTTP 502; contract: status 502 is not documented for /health", check.error
    assert_not check.ok?
  end

  test "a site without a contract only needs a 2xx" do
    assert Check.run(PORTFOLIO, http: respond_with(200, "<html></html>")).ok?
  end

  test "network errors are recorded as down" do
    check = Check.run(PORTFOLIO, http: ->(_uri) { raise Net::OpenTimeout, "execution expired" })

    assert_not check.ok?
    assert_equal "Net::OpenTimeout: execution expired", check.error
  end

  test "prune drops checks older than 30 days" do
    old = Check.create!(site_slug: "portfolio", ok: true, created_at: 31.days.ago)
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
