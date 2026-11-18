# A message someone sent me through a contact form. Everything is required: I reply to these.
class ContactMessage < Submission
  normalizes :name, :subject, :message, with: ->(value) { value.strip.presence }

  validates :name, :email, :subject, :message, presence: true
  validates :name, length: { maximum: 255 }
  validates :subject, length: { maximum: 500 }
  validates :message, length: { maximum: MAX_TEXT }
end
