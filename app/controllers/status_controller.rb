# GET /: public status of every site. No personal data here, so no login (unlike /forms).
class StatusController < ApplicationController
  skip_before_action :require_admin

  def index
    @sites = Site.all.map do |site|
      checks = site.checks.recent
      { site: site, latest: checks.first, history: checks.limit(48).to_a.reverse, uptime: checks.uptime }
    end
  end
end
