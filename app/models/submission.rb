# What every message sent from one of my sites shares: which site it came from, a cleaned-up
# email, newest-first listing and its JSON shape. ContactMessage and Feedback inherit from it.
class Submission < ApplicationRecord
  self.abstract_class = true

  MAX_TEXT = 5_000

  normalizes :email, with: ->(email) { email.strip.downcase.presence }

  validates :site, inclusion: { in: ->(_) { Site.all.map(&:slug) }, message: "is not a known site" }
  validates :email, length: { maximum: 255 }, format: { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/, allow_nil: true }

  scope :recent, -> { order(created_at: :desc) }

  def as_json(*) = attributes.except("updated_at").merge("created_at" => created_at&.utc&.iso8601)
end
