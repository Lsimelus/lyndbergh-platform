# Checks every site; runs every 5 minutes (config/recurring.yml). Keeps 30 days of history.
# Alerts when a site goes down or comes back.
class CheckSitesJob < ApplicationJob
  def perform
    Site.all.each do |site|
      previous = site.checks.recent.first
      Alert.status_changed(site, previous: previous, current: Check.run(site))
    end
    Check.prune
  end
end
