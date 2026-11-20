require "test_helper"

class FormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ContactMessage.create!(name: "Ada", email: "ada@example.com", subject: "Engineering role", message: "Free next week?")
    Feedback.create!(site: "real-calc", rating: 5, comment: "Great rankings", page: "/explore")
    Feedback.create!(site: "real-calc", rating: 3)
    Feedback.create!(site: "abchealth", comment: "Love the check-ins")
  end

  test "shows contact messages with a reply link, and feedback by site with its average" do
    get forms_path

    assert_response :success
    assert_select "h3", "Engineering role"
    assert_select "a.button[href^=?]", "mailto:ada@example.com?subject=Re%3A", text: "Reply"
    assert_select ".average b", "4.0"   # real-calc: (5 + 3) / 2
    assert_select ".average b", "—"     # abchealth: comments only
    assert_select ".body", "Great rankings"
  end

  test "is locked in production when Google sign-in isn't set up" do
    Rails.env.define_singleton_method(:local?) { false }
    get forms_path
    assert_redirected_to sign_in_path
  ensure
    Rails.env.singleton_class.remove_method(:local?)
  end
end
