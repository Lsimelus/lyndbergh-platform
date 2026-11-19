require "net/http"

# Tells me when something breaks. Both are off until their URL is set (in .env.production):
# - ALERT_URL: a site went down or came back. A plain-text POST, so an ntfy.sh topic URL
#   (push to my phone, no account) works as is.
# - HEARTBEAT_URL: pinged after every round of checks (a healthchecks.io check). If the server
#   or the job dies, the pings stop and healthchecks.io emails me.
module Alert
  TIMEOUT = 5

  # Called with a site's previous and new check; only a change (up -> down, down -> up) alerts.
  def self.status_changed(site, previous:, current:, post: method(:post))
    return if previous.nil? || previous.ok? == current.ok?

    message = current.ok? ? "#{site.name} is back up" : "#{site.name} is down: #{current.error || 'no response'}"
    post.call(ENV["ALERT_URL"], message, current.ok? ? "white_check_mark" : "rotating_light")
  end

  def self.heartbeat(post: method(:post)) = post.call(ENV["HEARTBEAT_URL"], "ok", nil)

  # Never raises: an alert that fails to send mustn't stop the checks.
  def self.post(url, body, tag)
    return if url.blank?

    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      headers = { "Content-Type" => "text/plain", "User-Agent" => "lyndbergh-platform-monitor" }
      headers["Tags"] = tag if tag
      http.post(uri.request_uri, body, headers)
    end
  rescue StandardError => e
    Rails.logger.warn("Alert to #{uri&.host} failed: #{e.class}: #{e.message}")
    nil
  end
end
