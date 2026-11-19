require "test_helper"

class Api::HeartbeatTest < ActionDispatch::IntegrationTest
  test "ok while checks are fresh" do
    Check.create!(site_slug: "portfolio", ok: true)
    get "/api/heartbeat"
    assert_response :success
  end

  test "unavailable when the newest check is stale, or there are none" do
    get "/api/heartbeat"
    assert_response :service_unavailable

    Check.create!(site_slug: "portfolio", ok: true, created_at: 20.minutes.ago)
    get "/api/heartbeat"
    assert_response :service_unavailable
    assert_equal "stale", response.parsed_body.dig("error", "code")
  end
end
