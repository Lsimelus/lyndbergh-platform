# Checks every site for the public status page; runs every 5 minutes (config/recurring.yml). Keeps 30 days of checks.
# Alerting (site down, errors, crashes) is New Relic's job: ping monitors and alert policies, to email and ntfy.
class CheckSitesJob < ApplicationJob
  def perform
    Site.all.each { |site| Check.run(site) }
    Check.prune
  end
end
