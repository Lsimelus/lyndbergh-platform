require "test_helper"

class StatusControllerTest < ActionDispatch::IntegrationTest
  test "lists every site with its latest result" do
    Check.create!(site_slug: "real-calc", ok: false, http_status: 503, error: "HTTP 503")

    get root_path

    assert_response :success
    Site.all.each { |site| assert_select "h2", site.name }
    assert_select ".error", "HTTP 503"
  end
end
