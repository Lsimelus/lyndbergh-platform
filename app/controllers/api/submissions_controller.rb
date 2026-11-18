# Parent of the public endpoints people post messages to (contact, feedback): rate limiting,
# the honeypot, and save -> log -> respond. Subclasses only build the record.
module Api
  class SubmissionsController < BaseController
    HONEYPOT = :website # a hidden field: people leave it empty, bots fill it in

    rate_limit to: 5, within: 10.minutes, only: :create,
               with: -> { render_error :too_many_requests, "Too many messages. Try again in a few minutes.", code: "rate_limited" }

    private

    def submit(record, event:)
      # Look like a success so the bot moves on, but keep nothing.
      return render_data(nil, status: :created) if params[HONEYPOT].present?
      return render_validation_errors(record) unless record.save

      EventLog.emit(event, session_id: session_id, request_id: request.request_id,
                           props: { site: record.site, rating: record.try(:rating) }.compact)
      render_data({ id: record.id, created_at: record.created_at.utc.iso8601 }, status: :created)
    end
  end
end
