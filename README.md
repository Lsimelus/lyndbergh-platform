# Lyndbergh Platform

A small Rails app that monitors my sites.

Every 5 minutes it requests each site's health URL and records whether it's up, its HTTP status and its latency. The status page shows 24-hour uptime and recent history, with links to each site's repo, CI and Dependabot alerts. APIs marked `expect: json` must also answer in JSON, which catches a host serving its HTML page where the API should be.

## Running it

```bash
bundle install
bin/rails db:prepare
bin/dev            # http://localhost:3000
bin/jobs           # runs the checks every 5 minutes
bin/rails test
```

Run one round of checks by hand: `bin/rails runner CheckSitesJob.perform_now`.
Add a site by adding an entry to `config/sites.yml`.

## TODO

- [ ] Deploy it (Kamal to the VPS planned for real-calc) and add it to the Portfolio.
- [ ] Alert when a site goes from up to down (email or a webhook).
- [ ] Move the Portfolio contact form backend here (`POST /api/contact-form`), with rate limiting and a honeypot field, then point the Portfolio at it and retire the FastAPI backend.
- [ ] Forms page: show contact form submissions, and read product forms (Real Calc feedback, ABCHealth) from each service's admin API without moving them.
- [ ] PR agents: review open PRs across my repos and push fixes for review comments, with a page here showing what each agent did.
