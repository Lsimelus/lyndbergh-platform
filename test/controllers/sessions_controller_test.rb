require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @env = ENV.to_h.slice("GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "ADMIN_EMAILS")
    ENV.update("GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret", "ADMIN_EMAILS" => "Owner@Example.com, other@example.com")
    OmniAuth.config.test_mode = true
  end

  teardown do
    %w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET ADMIN_EMAILS].each { |key| @env.key?(key) ? ENV[key] = @env[key] : ENV.delete(key) }
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  def google(email, verified: true)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "1", info: { email: email }, extra: { raw_info: { email_verified: verified.to_s } })
    post "/auth/google_oauth2"
    follow_redirect! # OmniAuth's test mode answers with the callback redirect
  end

  test "pages send people to sign in, then back where they were" do
    get forms_path
    assert_redirected_to sign_in_path

    google("owner@example.com")
    assert_redirected_to forms_path
    follow_redirect!
    assert_response :success
    assert_select "button", "Sign out"
  end

  test "refuses accounts that aren't admins, and unverified emails" do
    google("stranger@example.com")
    assert_redirected_to sign_in_path(error: "not_allowed")
    follow_redirect!
    assert_select ".error", /isn't allowed/

    google("owner@example.com", verified: false)
    assert_redirected_to sign_in_path(error: "not_allowed")
    get forms_path
    assert_redirected_to sign_in_path
  end

  test "signing out, an expired session or a removed admin locks the pages again" do
    google("owner@example.com")
    delete sign_out_path
    get forms_path
    assert_redirected_to sign_in_path

    google("owner@example.com")
    travel 8.days do
      get forms_path
      assert_redirected_to sign_in_path
    end

    google("other@example.com")
    ENV["ADMIN_EMAILS"] = "owner@example.com"
    get forms_path
    assert_redirected_to sign_in_path
  end

  test "return_to only goes to paths on this site" do
    get "//evil.example.com/x"
    google("owner@example.com")
    assert_redirected_to forms_path
  end
end
