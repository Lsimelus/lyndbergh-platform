# GET /forms: contact messages to reply to, and feedback by site. Personal data, so it's behind
# a password (ADMIN_PASSWORD, user ADMIN_USER or "admin"). Without a password set it's locked,
# except on my own machine (development and test).
class FormsController < ApplicationController
  before_action :require_admin

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

  private

  def require_admin
    password = ENV["ADMIN_PASSWORD"].presence
    return if password.nil? && Rails.env.local?
    return head(:forbidden) if password.nil?

    authenticate_or_request_with_http_basic("Forms") do |user, given|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch("ADMIN_USER", "admin")) &
        ActiveSupport::SecurityUtils.secure_compare(given, password)
    end
  end
end
