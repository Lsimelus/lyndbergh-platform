require "test_helper"

class StatusControllerTest < ActionDispatch::IntegrationTest
  test "lists every site with its latest result" do
    Check.create!(site_slug: "real-calc", ok: false, http_status: 503, error: "HTTP 503")

    get root_path

    assert_response :success
    Site.all.each { |site| assert_select "h2", site.name }
    assert_select ".error", "HTTP 503"
    assert_select "a[href='https://realcalc.lyndbergh.net/admin/telemetry']", "Traffic"
  end

  test "needs the admin password when one is set" do
    ENV["ADMIN_PASSWORD"] = "s3cret"
    get root_path
    assert_response :unauthorized

    get root_path, headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "s3cret") }
    assert_response :success
  ensure
    ENV.delete("ADMIN_PASSWORD")
  end
end
