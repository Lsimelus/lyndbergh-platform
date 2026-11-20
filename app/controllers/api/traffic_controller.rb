# POST /api/traffic: per-minute totals from script/traffic-collector on the server.
# Needs `Authorization: Bearer TRAFFIC_TOKEN`; without TRAFFIC_TOKEN set, nothing is accepted.
module Api
  class TrafficController < BaseController
    before_action :require_token

    def create
      render_data({ stored: TrafficMinute.record!(params.permit(rows: %i[host minute requests errors_4xx errors_5xx total_ms max_ms])
                                                         .fetch(:rows, []).map(&:to_h)) }, status: :created)
    end

    private

    def require_token
      token = ENV["TRAFFIC_TOKEN"].presence
      given = request.authorization.to_s.delete_prefix("Bearer ")
      return if token && ActiveSupport::SecurityUtils.secure_compare(given, token)

      render_error :unauthorized, "Missing or wrong token", code: "unauthorized"
    end
  end
end
