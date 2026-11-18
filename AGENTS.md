# Working in this repository

- Rails 8 app (SQLite, Solid Queue) that monitors my sites. Keep it small: no new gems, tables or services until a TODO in the README needs one.
- Sites live in `config/sites.yml`; the check is `app/models/check.rb`, run by `CheckSitesJob` (`config/recurring.yml`).
- This repo is public. Never commit secrets, account IDs or private URLs.
- Done means: `bin/rails test && bin/rubocop`.
- Commits: Conventional Commits, one squashed commit per batch of work.
