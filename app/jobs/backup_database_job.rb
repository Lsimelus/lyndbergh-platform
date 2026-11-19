# Copies the main SQLite database to storage/backups every night (config/recurring.yml) and keeps
# 14 days. Guards against a bad migration or deploy; Hetzner's server backups cover losing the disk.
class BackupDatabaseJob < ApplicationJob
  KEEP = 14

  def perform(dir: Rails.root.join("storage/backups"))
    FileUtils.mkdir_p(dir)
    path = File.join(dir, "#{Rails.env}-#{Date.current.iso8601}.sqlite3")
    FileUtils.rm_f(path)
    ActiveRecord::Base.connection.execute("VACUUM INTO #{ActiveRecord::Base.connection.quote(path)}")
    Dir.glob(File.join(dir, "#{Rails.env}-*.sqlite3")).sort.reverse.drop(KEEP).each { |old| File.delete(old) }
  end
end
