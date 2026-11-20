# Lyndbergh Platform

My roadmap, plus the small Rails app behind my sites: it monitors every site and holds the endpoints they share.

- **[Roadmap](#roadmap):** what I'm working on now and what's next across my projects.
- **[Platform app](#platform-app):** this repo's Rails app: the site monitor, plus the contact form and feedback endpoints every site shares.

<!-- walkthrough:start -->

## Roadmap

What I'm working on now and what's next.

### In progress

- [ ] Turn on real-calc's location advisor on Qwen 27B (decision 0013): pick an OpenAI-compatible host (OpenRouter, Together, Alibaba Model Studio or self-hosted), add ADVISOR_API_BASE / ADVISOR_API_KEY / ADVISOR_MODEL to the Kamal secrets, name the host on the privacy page, then ship the eval suite (golden test set + scored runs, incl. tool use and Fair Housing behaviour) — due 2026-12-31

### Up next

- [ ] abchealth-expressjs: add a CI workflow that runs the Jest tests; remove .vercel/ and deploy/vercel-redirect.json once the Kamal branch merges
- [ ] Finish real-calc's move to Hetzner: confirm the Market data workflow's SSH secrets are set and run it once, turn on Hetzner Backups, attach a 'web' firewall (TCP 22/80/443 + ICMP), replace the GitHub token (pasted in chat)
- [ ] PR review agent: install the Claude GitHub Action (/install-github-app) on Portfolio so every PR gets a review, then add it to real-calc, lyndbergh-platform, abchealth-expressjs and playlist-video-converter
- [ ] Weekly upkeep agent: write lyndbergh-platform/agents/upkeep.md (merge safe Dependabot bumps once tests pass, open a fix PR for red CI) and run it as a weekly /schedule routine across the active repos
- [ ] ABChealth: enroll in the Apple Developer Program (launch option C, private-first, is chosen) (from 2027-01-01)
- [ ] ABChealth [pre-Apple]: production Supabase has the 8 SQL files, RLS on every table and 12 articles (checked 2026-11-18); still to check: auth redirects + Google provider, then a full simulator test against prod (due 2026-12-31)
- [ ] ABChealth: take simulator screenshots and create the App Review demo account (listing copy is drafted in AppStore/LISTING.md) (before submit, 2027-02-02)
- [ ] ABChealth wire or delete the 3 unreachable screens (Create post, Activity, Profile) (before submit, 2027-02-02)
- [ ] ABChealth [post-Apple]: set team + Sign in with Apple, add Supabase Apple provider, upload 1.0 (1) to TestFlight and test on 2 iPhones (January 2027)
- [ ] ABChealth [post-Apple]: run an external TestFlight beta with 15-30 waitlist users; fix crashes only (January 2027)
- [ ] ABChealth [post-Apple]: submit for review 2027-02-02, launch 2027-02-08, email the waitlist, watch crash reports for 48h
- [ ] Race Me backend (raceMe-rails): models and race rules for distance, timed and multi-day races with Minitest tests, then the live RaceChannel and race lifecycle jobs (README build order 1–2)
- [ ] Race Me iOS (raceMe-ios): SwiftUI app that joins a race by code, tracks the run with CoreLocation and shows live positions from the API
- [ ] Watchmix deploy: watchmix.lyndbergh.net A record, production YouTube API key (server IP), replace the OAuth client secret + add the production redirect URI, Kamal config (Rails UI + converter accessory), add it to the platform's sites.yml, then start Google's OAuth verification and quota increase — due 2027-01-31

### Someday

- [ ] ABChealth launch: upgrade Supabase to Pro ($25/month) before real users (free projects pause after ~a week idle)

### Recently done

- [x] real-calc AWS teardown: terraform destroy (59 resources; RDS final snapshot kept), then infra/, infra.yml, AWS gems, the S3 path and the CloudWatch link removed (PR #17, deployed bbc1a22) (2026-11-19)
- [x] Watchmix ADR 0001: record that Python's reason (ytmusicapi) is gone; after launch, decide whether to move the matcher and Apple parser into the Rails app (one runtime, one image) (Watchmix #2, Portfolio #1) (2026-11-19)
- [x] Even out security scans: Brakeman for Watchmix's Rails UI, npm audit in Portfolio's and abchealth-expressjs's CI (Watchmix #2, Portfolio #1) (2026-11-19)
- [x] Dependabot (dependencies + github-actions) for Portfolio, Watchmix and abchealth-expressjs, and bring their CI actions up to date (checkout v4/v5 → v7) (Watchmix #2, Portfolio #1) (2026-11-19)
- [x] Portfolio cleanup: remove the unused react-pdf-viewer dependency and the stray build/ and frontend/ folders; add ESLint to CI like real-calc's frontend (or fix CLAUDE.md, which still says lint warnings fail the build) (Watchmix #2, Portfolio #1) (2026-11-19)

*Generated from my `/next-level` notes.*

<!-- walkthrough:end -->

## Platform app

A Rails 8 app (SQLite, Solid Queue) with three parts.

**Shared endpoints.** Anything more than one site needs lives here. Schemas, responses and the event-log format: [docs/schemas.md](docs/schemas.md).

| Endpoint | Used by |
|---|---|
| `POST /api/contact-form` | The Portfolio's contact form |
| `POST /api/feedback` | ABChealth's footer feedback form (rating and/or comment). Real Calc keeps its own in-app feedback. |

**Forms page** (`/forms`, password-protected). Contact messages, newest first, each with a Reply link, and feedback grouped by site with the average rating, how ratings are spread across 1–5, and recent comments. Set `ADMIN_PASSWORD` (and optionally `ADMIN_USER`, default `admin`); without it the page is locked everywhere except on my machine.

**Site monitor.** Every 5 minutes it requests each site's health URL and records whether it's up, its HTTP status and its latency. The status page shows 24-hour uptime and recent history, with links to each site's repo, CI and Dependabot alerts. APIs marked `expect: json` must also answer in JSON, which catches a host serving its HTML page where the API should be.

### Running it

```bash
bundle install
bin/rails db:prepare
bin/dev            # http://localhost:3004
bin/jobs           # runs the checks every 5 minutes
bin/rails test
```

Run one round of checks by hand: `bin/rails runner CheckSitesJob.perform_now`.
Add a site by adding an entry to `config/sites.yml`.

### Production

It runs at https://platform.lyndbergh.net, deployed with Kamal to the same Hetzner VPS as real-calc
(its own container behind the shared kamal-proxy). `bin/prod` wraps Kamal and loads `.env.production`
(gitignored) with `KAMAL_HOST`, `KAMAL_REGISTRY_PASSWORD` (GitHub token with write:packages) and
`ADMIN_PASSWORD` (the /forms login; the status page and API are public) and `ALERT_URL` (ntfy.sh topic for down/up pushes).
A scheduled GitHub Actions workflow calls `/api/heartbeat` every 10 minutes and pushes to the same
topic (repo secret `ALERT_URL`) if the server is down or its checks stopped. SQLite lives in the `lyndbergh_platform_storage` volume and a
nightly job copies it to `storage/backups` (14 days kept).

```bash
bin/prod deploy                     # ship the current commit
bin/prod logs                       # follow the logs
bin/prod import-contacts old.json   # load old contact messages (safe to re-run)
bin/prod health
```

### Local ports

Each repo has its own port so they can all run at once.

| Repo | Port |
|---|---|
| real-calc | 3000 (Vite 3036, end-to-end tests 3110) |
| abchealth-expressjs | 3001 |
| Portfolio | 3002 |
| lyndbergh-platform | 3004 |
| playlist-video-converter | 3100 (Rails UI), 8787 (server), 8788 (CLI sign-in) |
| Postgres | 5432 |

### TODO

- [x] Deploy it with Kamal on the same VPS as real-calc, with nightly SQLite backups.
- [x] A heartbeat from outside (GitHub Actions → `/api/heartbeat` every 10 minutes) so a dead server still alerts me.
- [x] Add it to the Portfolio (as "Ops Platform").
- [ ] PR-review agents on the Anthropic API (Managed Agents), after real-calc's advisor ships with its eval.
- [x] Alert when a site goes down or comes back (`ALERT_URL`, an ntfy.sh topic: push to my phone).
- [x] Contact form and feedback endpoints, with rate limiting and a honeypot.
- [x] Copy the old messages from fastapi-postgres (39 imported 2026-11-18).
- [x] Point the Portfolio's `REACT_APP_API_URL` here (Vercel env only) and retire the FastAPI backend.
- [x] Feedback form on ABChealth that posts to `/api/feedback` (Real Calc keeps its own signed-in feedback, deleted with the account).
- [ ] Add `session_id` to real-calc's request log (event-log format) and mention it on its privacy page.
- [x] Forms page: contact messages to reply to, and feedback by site with average ratings.
