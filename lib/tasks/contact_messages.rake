namespace :contact_messages do
  # Loads contact messages from a JSON array on STDIN ([{name, email, subject, message, created_at}]),
  # keeping their original timestamps. Used once to copy fastapi-postgres's contact_forms rows.
  # Safe to re-run: a message with the same email and created_at is skipped.
  desc "Import contact messages from JSON on STDIN"
  task import: :environment do
    rows = JSON.parse($stdin.read)
    added = rows.count do |row|
      created = Time.iso8601(row.fetch("created_at"))
      next false if ContactMessage.exists?(email: row.fetch("email").strip.downcase, created_at: created)

      ContactMessage.create!(site: row.fetch("site", "portfolio"), name: row.fetch("name"), email: row.fetch("email"),
                             subject: row.fetch("subject"), message: row.fetch("message"),
                             created_at: created, updated_at: created)
    end
    puts "Imported #{added} of #{rows.size} contact messages"
  end
end
