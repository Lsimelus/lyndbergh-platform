require "test_helper"

class TrafficControllerTest < ActionDispatch::IntegrationTest
  test "shows each site's traffic" do
    TrafficMinute.record!([ { "host" => "realcalc.lyndbergh.net", "minute" => 10.minutes.ago.iso8601, "requests" => 1234, "errors_5xx" => 2 } ])
    get "/traffic"
    assert_response :success
    assert_select "section#real-calc dd", text: "1,234"
    assert_select "section#portfolio a[href^='https://vercel.com']", "its analytics"
  end

  test "the status page links each server site to its traffic, Portfolio to Vercel" do
    get "/"
    assert_select "a[href='/traffic#real-calc']", "Traffic"
    assert_select "a[href^='https://vercel.com']", "Traffic"
  end
end
