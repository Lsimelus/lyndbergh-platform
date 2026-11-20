class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  SESSION_LENGTH = 7.days

  # Pages are for me only unless they opt out (the status page does; the JSON API under Api:: has its own base class).
  # Sign in with Google as one of ADMIN_EMAILS (comma separated). Without a Google client configured, pages are
  # open on my own machine (development and test) and locked everywhere else.
  before_action :require_admin
  helper_method :current_admin

  private

  def current_admin
    email, signed_in_at = session[:admin_email], session[:admin_signed_in_at]
    return unless email && signed_in_at && Time.zone.at(signed_in_at) > SESSION_LENGTH.ago

    email if self.class.admin_emails.include?(email)
  end

  def require_admin
    return if current_admin
    return if !self.class.google_configured? && Rails.env.local?

    session[:return_to] = request.fullpath if request.get? || request.head?
    redirect_to sign_in_path
  end

  def self.admin_emails = ENV.fetch("ADMIN_EMAILS", "").split(",").map { |e| e.strip.downcase }.compact_blank
  def self.google_configured? = ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
end
