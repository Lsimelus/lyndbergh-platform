require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  def contact(**attrs) = ContactMessage.new(name: "Ada", email: "ada@example.com", subject: "Hi", message: "Hello", **attrs)

  test "a complete contact message is valid and defaults to the portfolio" do
    message = contact
    assert message.valid?
    assert_equal "portfolio", message.site
  end

  test "contact messages need every field" do
    message = ContactMessage.new(name: " ", email: "", subject: nil, message: "  ")
    assert_not message.valid?
    assert_equal %i[email message name subject], message.errors.attribute_names.sort
  end

  test "emails are cleaned up and must look like an email" do
    assert_equal "ada@example.com", contact(email: "  Ada@Example.COM ").tap(&:valid?).email
    assert_includes contact(email: "not-an-email").tap(&:valid?).errors.attribute_names, :email
  end

  test "the site must be one of mine" do
    assert_includes contact(site: "someone-else").tap(&:valid?).errors.attribute_names, :site
  end

  test "feedback can be anonymous with just a rating or just a comment" do
    assert Feedback.new(site: "real-calc", rating: 5).valid?
    assert Feedback.new(site: "abchealth", comment: "Love the check-ins").valid?
  end

  test "feedback needs a rating or a comment, and ratings are 1-5" do
    empty = Feedback.new(site: "real-calc", comment: "  ")
    assert_not empty.valid?
    assert_includes empty.errors.full_messages, "Add a rating, a comment, or both"
    assert_not Feedback.new(site: "real-calc", rating: 6).valid?
  end

  test "deleting an account deletes only that user's feedback on that site" do
    Feedback.create!(site: "real-calc", rating: 4, user_ref: "42")
    kept = Feedback.create!(site: "abchealth", rating: 4, user_ref: "42")
    Feedback.delete_for(site: "real-calc", user_ref: "42")
    assert_equal [ kept ], Feedback.all.to_a
  end
end
