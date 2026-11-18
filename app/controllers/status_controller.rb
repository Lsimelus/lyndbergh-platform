class StatusController < ApplicationController
  def index
    @sites = Site.all.map do |site|
      checks = site.checks.recent
      { site: site, latest: checks.first, history: checks.limit(48).to_a.reverse, uptime: checks.uptime }
    end
  end
end
