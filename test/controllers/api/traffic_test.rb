require "test_helper"

class Api::TrafficTest < ActionDispatch::IntegrationTest
  setup { ENV["TRAFFIC_TOKEN"] = "secret-token" }
  teardown { ENV.delete("TRAFFIC_TOKEN") }

  def rows = [ { host: "realcalc.lyndbergh.net", minute: "2026-11-20T01:46:00Z", requests: 3, errors_4xx: 0, errors_5xx: 1, total_ms: 30, max_ms: 20 } ]

  test "stores totals sent with the token" do
    post "/api/traffic", params: { rows: rows }, as: :json, headers: { "Authorization" => "Bearer secret-token" }
    assert_response :created
    assert_equal 1, response.parsed_body.dig("data", "stored")
    assert_equal 3, TrafficMinute.sole.requests
  end

  test "refuses a wrong or missing token, and everything when no token is configured" do
    post "/api/traffic", params: { rows: rows }, as: :json, headers: { "Authorization" => "Bearer nope" }
    assert_response :unauthorized
    post "/api/traffic", params: { rows: rows }, as: :json
    assert_response :unauthorized
    ENV.delete("TRAFFIC_TOKEN")
    post "/api/traffic", params: { rows: rows }, as: :json, headers: { "Authorization" => "Bearer " }
    assert_response :unauthorized
    assert_equal 0, TrafficMinute.count
  end
end
