# GET /api/heartbeat: 200 while the site checks keep running, 503 when the newest check is older
# than STALE. Called from outside by .github/workflows/heartbeat.yml, which alerts me when this
# fails or the server doesn't answer at all.
module Api
  class HeartbeatController < BaseController
    STALE = 15.minutes

    def show
      last = Check.maximum(:created_at)
      if last && last > STALE.ago
        render_data({ last_check_at: last.utc.iso8601 })
      else
        render_error :service_unavailable, "No site check in the last #{STALE.inspect}", code: "stale"
      end
    end
  end
end
