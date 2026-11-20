# Sign in with Google; only ADMIN_EMAILS with a Google-verified address get in.
class SessionsController < ApplicationController
  skip_before_action :require_admin

  def new
    @error = { "not_allowed" => "That Google account isn't allowed here.", "access_denied" => "Sign-in was cancelled." }
      .fetch(params[:error].to_s) { params[:error].present? ? "Google sign-in failed. Try again." : nil }
  end

  def create
    auth = request.env["omniauth.auth"]
    email = auth&.dig("info", "email").to_s.strip.downcase
    verified = auth&.dig("extra", "raw_info", "email_verified").to_s == "true"
    unless verified && self.class.admin_emails.include?(email)
      Rails.logger.warn("Sign-in refused for a Google account not in ADMIN_EMAILS")
      return redirect_to sign_in_path(error: "not_allowed")
    end

    return_to = session[:return_to]
    reset_session # a fresh session id on sign-in
    session[:admin_email] = email
    session[:admin_signed_in_at] = Time.current.to_i
    redirect_to safe_path(return_to) || forms_path
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  private

  # Only paths on this site, so a crafted return_to can't send someone elsewhere after signing in.
  def safe_path(path)
    path if path.to_s.start_with?("/") && !path.to_s.start_with?("//")
  end
end
