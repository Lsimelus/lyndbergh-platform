require "test_helper"

class StatusControllerTest < ActionDispatch::IntegrationTest
  test "lists every site with its latest result" do
    Check.create!(site_slug: "real-calc", ok: false, http_status: 503, error: "HTTP 503")

    get root_path

    assert_response :success
    Site.all.each { |site| assert_select "h2", site.name }
    assert_select ".error", "HTTP 503"
    assert_select "a[href='https://one.newrelic.com/nr1-core']", "Traffic"
    assert_select "a[href='https://abchealth.lyndbergh.net/admin/']", "Admin"
  end

  test "is public even when admin sign-in is set up" do
    ENV.update("GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret", "ADMIN_EMAILS" => "owner@example.com")
    get root_path
    assert_response :success
  ensure
    %w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET ADMIN_EMAILS].each { |key| ENV.delete(key) }
  end
end
