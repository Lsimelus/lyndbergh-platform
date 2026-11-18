# Feedback from a product's feedback button: a 1-5 rating, a comment, or both. Anonymous is fine.
class Feedback < Submission
  self.table_name = "feedback"

  normalizes :comment, :page, :user_ref, with: ->(value) { value.strip.presence }

  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
  validates :comment, length: { maximum: MAX_TEXT }
  validates :page, length: { maximum: 500 }
  validates :user_ref, length: { maximum: 255 }
  validate :rating_or_comment

  # When someone deletes their account on a site, their feedback goes too.
  def self.delete_for(site:, user_ref:) = where(site: site, user_ref: user_ref).delete_all

  private

  def rating_or_comment
    errors.add(:base, "Add a rating, a comment, or both") if rating.nil? && comment.nil?
  end
end
