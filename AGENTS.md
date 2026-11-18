# Working in this repository

- Rails 8 app (SQLite, Solid Queue): the site monitor plus the endpoints my sites share (contact form, feedback). Keep it small: no new gems, tables or services until a TODO in the README needs one.
- Shared endpoints live in `app/controllers/api/` under `Api::BaseController` (envelope + request logging); public submissions under `Api::SubmissionsController` (rate limit + honeypot). Models share `Submission`. Follow `docs/schemas.md`, and never log personal data.
- Sites live in `config/sites.yml`; the check is `app/models/check.rb`, run by `CheckSitesJob` (`config/recurring.yml`).
- This repo is public. Never commit secrets, account IDs or private URLs.
- Done means: `bin/rails test && bin/rubocop`.
- Commits: Conventional Commits, one squashed commit per batch of work.
