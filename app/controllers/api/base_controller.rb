# Parent of every JSON endpoint other sites call. Every response is an envelope:
# {data, meta, error}. Every request is logged as an event-log `request` line (docs/schemas.md).
module Api
  class BaseController < ActionController::API
    around_action :log_request

    private

    def render_data(data, status: :ok, meta: nil)
      render json: { data: data, meta: meta, error: nil }, status: status
    end

    def render_error(status, message, code:, details: nil)
      render json: { data: nil, meta: nil, error: { message: message, code: code, details: details }.compact }, status: status
    end

    def render_validation_errors(record)
      errors = record.errors.map { |e| { loc: [ "body", e.attribute.to_s ], msg: e.full_message, type: e.type.to_s } }
      render_error :unprocessable_content, "Request validation failed", code: "validation_error", details: { errors: errors }
    end

    # Browsers send a random per-session id so backend events line up with page views.
    def session_id = request.headers["X-Session-Id"]

    def log_request
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
    ensure
      EventLog.emit("request", session_id: session_id, request_id: request.request_id, method: request.method,
                               route: request.route_uri_pattern&.delete_suffix("(.:format)"), status: response.status,
                               duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(1))
    end
  end
end
