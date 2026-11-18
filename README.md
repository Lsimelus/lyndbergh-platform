# Lyndbergh Platform

A small Rails app that monitors my sites, plus the shared API contracts my repos build against.

## What it does

- **Status page.** Every 5 minutes it requests each site's health URL and records whether it's up, its HTTP status and its latency. The page shows 24-hour uptime and recent history, with links to each site's repo, CI and Dependabot alerts.
- **Live contract checks.** For services with an OpenAPI contract, the health response is also validated against the spec. A site can return 200 and still be marked down when it doesn't match its contract (for example, a deploy that serves HTML where the API should be).
- **Shared contracts.** Each service owns its `openapi.yaml` next to its code. This repo holds what they share (the `{data, meta, error}` response envelope in `contracts/common/`), pulls each service's spec at a pinned ref, and generates TypeScript types for the frontends.

## Layout

| Path | What's there |
|---|---|
| `config/sites.yml` | The sites to monitor |
| `config/contracts.yml` | Where each service's spec lives (repo, path, ref) |
| `contracts/common/envelope.yaml` | Shared response envelope and error responses |
| `contracts/vendor/<service>/` | Specs pulled from the service repos (don't edit here) |
| `contracts/dist/`, `clients/ts/` | Bundled specs and generated TypeScript types (committed; CI checks they're current) |
| `app/models/check.rb`, `contract.rb` | The health check and the contract validation |

## Running it

```bash
bundle install && npm install
bin/rails db:prepare
bin/dev            # http://localhost:3000
bin/jobs           # runs the checks every 5 minutes
bin/rails test
```

Run one round of checks by hand: `bin/rails runner CheckSitesJob.perform_now`.

## Changing an API

1. Edit `openapi.yaml` in the service's repo first, then the code, in the same PR.
2. Here: bump `ref` in `config/contracts.yml` if it's pinned, then `bin/rails contracts:pull && npm run contracts`.
3. Commit the regenerated `contracts/dist/` and `clients/ts/`.

Service specs refer to the shared envelope by a tagged URL, e.g.
`https://raw.githubusercontent.com/Lsimelus/lyndbergh-platform/v0.1.0/contracts/common/envelope.yaml#/components/schemas/ErrorEnvelope`.

## Using the types

```bash
npm install --save-dev github:Lsimelus/lyndbergh-platform#v0.1.0
```

```ts
import type { RealCalc } from "@lyndbergh/contracts";
type ContactForm = RealCalc.components["schemas"]["ContactFormRequest"];
```
