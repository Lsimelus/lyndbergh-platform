# Admin sign-in is Google only (SessionsController). The sign-in page POSTs to /auth/google_oauth2 with the Rails
# CSRF token (omniauth-rails_csrf_protection checks it); Google sends people back to /auth/google_oauth2/callback.
# Tests use OmniAuth.config.test_mode; nothing calls Google from a test.
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch("GOOGLE_CLIENT_ID", ""), ENV.fetch("GOOGLE_CLIENT_SECRET", ""),
           scope: "openid,email", prompt: "select_account", access_type: "online"
end

OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.logger = Rails.logger
OmniAuth.config.on_failure = lambda do |env|
  reason = env["omniauth.error.type"].to_s.presence || "unknown"
  Rails.logger.warn("Google sign-in failed: #{reason}")
  [ 302, { "location" => "/sign-in?error=#{Rack::Utils.escape(reason)}" }, [] ]
end
