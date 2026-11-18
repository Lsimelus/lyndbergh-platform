# Checks every site; runs every 5 minutes (config/recurring.yml). Keeps 30 days of history.
class CheckSitesJob < ApplicationJob
  def perform
    Site.all.each { |site| Check.run(site) }
    Check.prune
  end
end
