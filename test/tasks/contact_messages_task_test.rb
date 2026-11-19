require "test_helper"
require "rake"

class ContactMessagesTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("contact_messages:import")
    @task = Rake::Task["contact_messages:import"]
  end

  def import(rows)
    $stdin = StringIO.new(rows.to_json)
    capture_io { @task.reenable; @task.invoke }
  ensure
    $stdin = STDIN
  end

  test "keeps original timestamps and skips rows already imported" do
    rows = [ { name: "Ada", email: "Ada@Example.com", subject: "Hi", message: "Hello", created_at: "2025-11-15T13:47:27.555863+00:00" } ]

    assert_difference -> { ContactMessage.count }, 1 do
      import(rows)
      import(rows)
    end
    message = ContactMessage.recent.first
    assert_equal "portfolio", message.site
    assert_equal Time.utc(2025, 11, 15, 13, 47, 27.555863r), message.created_at
  end
end
