# Working in this repository

- Rails 8 app (SQLite, Solid Queue) plus contract tooling (npm). Keep it small: no new gems, tables or services unless a real need shows up.
- Sites to monitor live in `config/sites.yml`; contract sources in `config/contracts.yml`.
- Never edit `contracts/vendor/`, `contracts/dist/` or `clients/ts/` by hand. Change the spec in the service repo, then `bin/rails contracts:pull && npm run contracts`.
- `contracts/common/envelope.yaml` is shared by every service: a breaking change there needs a new tag and an update in each service that uses it.
- This repo is public. Never commit secrets, account IDs or private URLs.
- Done means: `bin/rails test && bin/rubocop && npm run contracts && git diff --exit-code contracts/dist clients/ts`.
- Commits: Conventional Commits, one squashed commit per batch of work.
