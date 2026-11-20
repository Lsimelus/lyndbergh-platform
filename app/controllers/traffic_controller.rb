# GET /traffic: requests, errors and response times per site, from kamal-proxy's log. Behind the admin login.
class TrafficController < ApplicationController
  def index
    @sites = Site.all.map do |site|
      scope = TrafficMinute.where(site_slug: site.slug)
      { site: site, day: scope.where(minute: 24.hours.ago..).totals, month: scope.where(minute: 30.days.ago..).totals,
        hourly: scope.series(since: 23.hours.ago, step: 1.hour), daily: scope.series(since: 29.days.ago, step: 1.day),
        last_at: scope.maximum(:minute) }
    end
  end
end
