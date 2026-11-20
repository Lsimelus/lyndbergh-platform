# Lyndbergh Platform

My roadmap, plus the small Rails app behind my sites: it monitors every site and holds the endpoints they share.

- **[Roadmap](#roadmap):** what I'm working on now and what's next across my projects.
- **[Platform app](#platform-app):** this repo's Rails app: the site monitor, plus the contact form and feedback endpoints every site shares.

<!-- walkthrough:start -->

## Roadmap

What I'm working on, in order, and what comes after.

### Before 2027

*In order. Goals: ABChealth submitted to App Review, and the real-calc advisor tested and live in production.*

- [ ] New Relic, real-calc: send its JSON request logs to New Relic so logs sit next to traces (pick the cheapest way: OTLP logs from Rails vs a log forwarder on the server)
- [ ] ABChealth iOS crash reporting with New Relic Mobile: merge PR #2 (agent wired in, crashes only, Xcode project now in git), create the iOS app in New Relic and put its token in Config.xcconfig as NEW_RELIC_APP_TOKEN, add the dSYM upload step so crashes are readable, then one test crash visible in New Relic before TestFlight
- [ ] ABChealth iOS CI: now that the Xcode project is in git, a GitHub Actions job that builds and runs the 21 unit tests on every PR (macOS runner minutes cost 10x; run on PRs only)
- [ ] New Relic alerts: 5xx rate, slow responses, advisor turn failures and app crashes → email + ntfy; decide which failures go through New Relic vs real-calc's own alert vs Resend
- [ ] Clean up: retire real-calc Admin → Telemetry (request_metrics) now that New Relic has it; remove unused libraries (opentelemetry-instrumentation-all → only what's used, old majors); delete old data (AWS RDS final snapshot + Terraform state bucket, leftover Neon references)
- [ ] Refine logs: one JSON event format across real-calc, ABChealth and the platform; drop noisy lines; never log personal data; check them in New Relic
- [ ] Slim the platform, no redundancy: keep status/uptime monitor, ntfy + heartbeat, contact/feedback endpoints, /forms and sign-in; remove /traffic and the server collector once New Relic covers real-calc and ABChealth; drop anything else New Relic now does
- [ ] Advisor eval on OpenRouter: add ~$5 credit; eval/cases.yml (~15 questions incl. Fair Housing) + bin/rails location_advisor:eval with a scorecard; measure tokens per question and set the monthly budget from it
- [ ] Advisor work until it's ready to deploy: fix what the evals catch, name OpenRouter on real-calc's privacy page, admin cost per user, rerun evals until they pass
- [ ] Review the whole suite (all repos, CI, deploys, monitoring, docs) for improvements before launch
- [ ] Secrets before the advisor goes to production: rotate everything pasted in chat (GitHub token → write:packages only, ABChealth Google OAuth secret, OpenRouter key, New Relic license key, YouTube dev key) and move .env.production files into a secret manager Kamal can read (1Password, Bitwarden or Doppler)
- [ ] Advisor to production: production OpenRouter key with a monthly cap, ADVISOR_ENABLED, tracing on; watch the first real turns in New Relic
- [ ] ABChealth: enroll in the Apple Developer Program (moved up to December so review can happen before 2027)
- [ ] ABChealth: production Supabase checks (auth redirects, Google provider) and a full simulator test against production
- [ ] ABChealth: Sign in with Apple (App Store rule 4.8: apps offering Google sign-in must offer Apple too) + Supabase Apple provider
- [ ] ABChealth: wire or delete the 3 unreachable screens (Create post, Activity, Profile); simulator screenshots; App Review demo account
- [ ] ABChealth: TestFlight build on 2 iPhones, then submit for App Review — before 2027

### Once we have active users

*Starts with the first real users of ABChealth or the advisor.*

- [ ] Resend: verify lyndbergh.net (and ABChealth's domain), send password-reset emails to users through it (Supabase custom SMTP for ABChealth), and real-calc's admin alert emails
- [ ] Failure notices: decide which failures email users (Resend) vs alert me (New Relic → email/ntfy), e.g. a failed save or advisor error
- [ ] ABChealth: upgrade Supabase to Pro ($25/month) before real users — free projects pause after ~a week idle
- [ ] ABChealth launch: external TestFlight beta with 15–30 waitlist users, release, email the waitlist, watch crashes for 48h
- [ ] Advisor: raise per-user token budgets from real usage; watch cost per user

### 2027

*After the Apple Developer license and launches.*

- [ ] Watchmix deploy (once the Apple Developer license exists): watchmix.lyndbergh.net, production YouTube API key (server IP), new OAuth secret, Kamal (Rails UI + converter accessory), add to the platform monitor; then Google OAuth verification and the YouTube quota increase
- [ ] Watchmix: Apple Music reader and writer (MusicKit): read private playlists, save Apple Music video playlists
- [ ] Watchmix: Sign in with Apple
- [ ] Make sure the app works on iPad (ABChealth is iPhone-only today; confirm which app)
- [ ] Dependabot auto-merge for patch/minor updates in real-calc, platform, Portfolio and Watchmix (replaces the upkeep agent)
- [ ] PR review agent: Claude GitHub Action on Portfolio, then the other repos
- [ ] Watchmix: decide whether to move the matcher and Apple parser into Rails (ADR 0001 note)

### Race Me (on hold)

*Don't start until the advisor is live in production or ABChealth is in the App Store.*

- [ ] Race Me stack (proposal): Rails 8 API + Postgres, Solid Cable (live positions over WebSockets) + Solid Queue (race timers, finish detection); SwiftUI + CoreLocation + HealthKit; Sign in with Apple; APNs push; New Relic from day one; Kamal on its own small Hetzner server (the shared one is near its memory limit); reuse ABChealth's iOS and Supabase lessons
- [ ] Race Me backend MVP: models and race rules (distance, timed, multi-day) with Minitest, then RaceChannel and race lifecycle jobs
- [ ] Race Me iOS MVP: join a race by code, track the run with CoreLocation, show live positions

### Recently done

- [x] ABChealth's old Vercel project deleted (old address 404; its stored Neon URL and Google secret gone); Supabase Auth URLs moved to abchealth.lyndbergh.net (2026-11-20)
- [x] New Relic, ABChealth site: tracing (HTTP, Express, Postgres, outgoing calls; ~37 MB) + one JSON log line per request, deployed (6f93468) (2026-11-20)
- [x] Old Vercel address removed everywhere: Portfolio links (live), iOS websiteURL, ABChealth docs/openapi; Vercel-only build script and redirect file deleted (2026-11-20)
- [x] New Relic, real-calc: tracing live in production (PR #22, 6fdedc7): requests, SQL (values masked), model calls, and advisor.turn / advisor.tool spans (2026-11-20)
- [x] lyndbergh-platform /traffic: kamal-proxy log → per-minute totals every 5 min (cron collector), requests/errors/latency per site, 90 days; replaces real-calc's broken Telemetry link (PR #4) (2026-11-19)

*Generated from my `/next-level` notes.*

<!-- walkthrough:end -->

## Platform app

A Rails 8 app (SQLite, Solid Queue) with four parts.

**Shared endpoints.** Anything more than one site needs lives here. Schemas, responses and the event-log format: [docs/schemas.md](docs/schemas.md).

| Endpoint | Used by |
|---|---|
| `POST /api/contact-form` | The Portfolio's contact form |
| `POST /api/feedback` | ABChealth's footer feedback form (rating and/or comment). Real Calc keeps its own in-app feedback. |

**Forms page** (`/forms`, admin sign-in). Contact messages, newest first, each with a Reply link, and feedback grouped by site with the average rating, how ratings are spread across 1–5, and recent comments. Sign in with Google: only `ADMIN_EMAILS` (comma separated) with a Google-verified address get in, for 7 days (`/sign-in`, *Sign out* in the nav). Without `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` the page is locked everywhere except on my machine.

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
`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` and `ADMIN_EMAILS` (the admin sign-in; Google redirect URI
`https://platform.lyndbergh.net/auth/google_oauth2/callback`; the status page and API are public), `ALERT_URL` (ntfy.sh
topic for down/up pushes).
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
