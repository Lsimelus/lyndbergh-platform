# Writes one JSON line per event in the shared event-log format (docs/schemas.md), so every app's
# logs read the same way and a person's path can be followed by session_id.
# Never put emails, names, message text or query strings in props.
module EventLog
  APP = "lyndbergh-platform"
  SESSION_ID = /\A[\w-]{1,64}\z/

  def self.emit(event, session_id: nil, user_id: nil, request_id: nil, **fields)
    line = { ts: Time.now.utc.iso8601(3), app: APP, env: Rails.env, event: event,
             session_id: session_id.to_s.match?(SESSION_ID) ? session_id : nil,
             user_id: user_id, request_id: request_id, **fields }
    Rails.logger.info(line.to_json)
    line
  end
end
