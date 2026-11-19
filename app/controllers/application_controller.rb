class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Every page is for me only (the JSON API under Api:: has its own base class and stays open).
  # Password is ADMIN_PASSWORD, user ADMIN_USER or "admin". Without a password set, pages are
  # locked, except on my own machine (development and test).
  before_action :require_admin

  private

  def require_admin
    password = ENV["ADMIN_PASSWORD"].presence
    return if password.nil? && Rails.env.local?
    return head(:forbidden) if password.nil?

    authenticate_or_request_with_http_basic("lyndbergh-platform") do |user, given|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch("ADMIN_USER", "admin")) &
        ActiveSupport::SecurityUtils.secure_compare(given, password)
    end
  end
end
