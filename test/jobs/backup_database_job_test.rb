require "test_helper"

class BackupDatabaseJobTest < ActiveSupport::TestCase
  self.use_transactional_tests = false # SQLite can't VACUUM inside a transaction
  test "writes today's copy and keeps the newest 14" do
    Dir.mktmpdir do |dir|
      20.times { |i| FileUtils.touch(File.join(dir, "test-2026-01-#{format('%02d', i + 1)}.sqlite3")) }

      BackupDatabaseJob.perform_now(dir: dir)

      files = Dir.children(dir).sort
      assert_equal BackupDatabaseJob::KEEP, files.size
      assert_includes files, "test-#{Date.current.iso8601}.sqlite3"
      assert File.size(File.join(dir, "test-#{Date.current.iso8601}.sqlite3")).positive?
    end
  end
end
