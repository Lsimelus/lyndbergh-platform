# GET /forms: contact messages to reply to, and feedback by site (behind the admin login).
class FormsController < ApplicationController
  def index
    @messages = ContactMessage.recent.limit(100)
    rated = Feedback.where.not(rating: nil)
    @feedback = Feedback.distinct.order(:site).pluck(:site).map do |site|
      {
        site: Site.find(site),
        count: Feedback.where(site: site).count,
        average: rated.where(site: site).average(:rating)&.round(1),
        ratings: (1..5).index_with { |stars| rated.where(site: site, rating: stars).count },
        recent: Feedback.where(site: site).recent.limit(50)
      }
    end
  end
end
