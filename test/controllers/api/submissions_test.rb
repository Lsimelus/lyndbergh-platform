require "test_helper"

class Api::SubmissionsTest < ActionDispatch::IntegrationTest
  CONTACT = { name: "Ada", email: "ada@example.com", subject: "Engineering role", message: "Are you free next week?" }.freeze

  setup { Rails.cache.clear }

  def envelope = JSON.parse(response.body)

  test "the Portfolio's contact form saves a message" do
    post "/api/contact-form", params: CONTACT, as: :json

    assert_response :created
    assert_nil envelope["error"]
    message = ContactMessage.find(envelope.dig("data", "id"))
    assert_equal [ "portfolio", "Ada", "Engineering role" ], [ message.site, message.name, message.subject ]
  end

  test "invalid input lists every failed field" do
    post "/api/contact-form", params: CONTACT.merge(email: "nope", subject: ""), as: :json

    assert_response :unprocessable_content
    assert_equal "validation_error", envelope.dig("error", "code")
    assert_equal %w[email subject], envelope.dig("error", "details", "errors").map { |e| e["loc"].last }.sort
    assert_equal 0, ContactMessage.count
  end

  test "anonymous feedback with a rating and a comment" do
    post "/api/feedback", params: { site: "real-calc", rating: 4, comment: "Great rankings", page: "/explore" }, as: :json

    assert_response :created
    feedback = Feedback.sole
    assert_equal [ 4, "Great rankings", "/explore", nil ], [ feedback.rating, feedback.comment, feedback.page, feedback.email ]
  end

  test "feedback with neither a rating nor a comment is rejected" do
    post "/api/feedback", params: { site: "abchealth" }, as: :json

    assert_response :unprocessable_content
    assert_equal "Add a rating, a comment, or both", envelope.dig("error", "details", "errors", 0, "msg")
  end

  test "bots that fill in the honeypot get a success but nothing is saved" do
    post "/api/contact-form", params: CONTACT.merge(website: "http://spam.example"), as: :json

    assert_response :created
    assert_equal 0, ContactMessage.count
  end

  test "more than 5 messages in 10 minutes from one address is rate limited" do
    5.times { post "/api/contact-form", params: CONTACT, as: :json }
    post "/api/contact-form", params: CONTACT, as: :json

    assert_response :too_many_requests
    assert_equal "rate_limited", envelope.dig("error", "code")
    assert_equal 5, ContactMessage.count
  end

  test "my sites may call it from the browser" do
    process :options, "/api/contact-form", headers: { "Origin" => "https://www.lyndbergh.net", "Access-Control-Request-Method" => "POST" }
    assert_equal "https://www.lyndbergh.net", response.headers["Access-Control-Allow-Origin"]

    process :options, "/api/contact-form", headers: { "Origin" => "https://evil.example", "Access-Control-Request-Method" => "POST" }
    assert_nil response.headers["Access-Control-Allow-Origin"]
  end

  test "logs the request and the submission as event-log lines, without personal data" do
    lines = []
    logger = ActiveSupport::Logger.new(StringIO.new).tap { |l| l.formatter = ->(*, msg) { lines << msg; "" } }
    original, Rails.logger = Rails.logger, logger
    begin
      post "/api/feedback", params: { site: "real-calc", rating: 5, comment: "secret words", email: "ada@example.com" },
                            headers: { "X-Session-Id" => "s_abc123" }, as: :json
    ensure
      Rails.logger = original
    end
    events = lines.filter_map { |l| JSON.parse(l) rescue nil }.index_by { |e| e["event"] }

    assert_equal({ "site" => "real-calc", "rating" => 5 }, events["feedback_submitted"]["props"])
    assert_equal "s_abc123", events["request"]["session_id"]
    assert_equal [ "/api/feedback", 201 ], events["request"].values_at("route", "status")
    assert_no_match(/secret words|ada@example/, lines.join)
  end
end
