# Shared schemas

Every app follows these, so messages land in one place and logs read the same way everywhere.
Endpoints live in this app (`app/controllers/api/`); every response is `{ "data": …, "meta": …, "error": … }`.

## Contact messages

Someone wants to reach me. `POST /api/contact-form` (the Portfolio's form). Table `contact_messages`.

| Field | Type | Rules |
|---|---|---|
| `site` | string | a slug from `config/sites.yml`; defaults to `portfolio` |
| `name` | string | required; ≤ 255 |
| `email` | string | required; valid email; ≤ 255 |
| `subject` | string | required; ≤ 500 |
| `message` | text | required; ≤ 5,000 |
| `created_at` | datetime | automatic |

## Feedback

A product's feedback button: rate the experience and/or leave a comment. Anonymous is fine.
`POST /api/feedback`. Table `feedback`.

| Field | Type | Rules |
|---|---|---|
| `site` | string | required; a slug from `config/sites.yml` (`real-calc`, `abchealth`, …) |
| `rating` | integer | 1–5; optional |
| `comment` | text | optional; ≤ 5,000. A rating, a comment, or both |
| `page` | string | where it was sent from, e.g. `/explore`; ≤ 500 |
| `user_ref` | string | the site's own user id when signed in; used to delete feedback with the account |
| `email` | string | optional; valid email if given |
| `created_at` | datetime | automatic |

```json
{ "site": "real-calc", "rating": 4, "comment": "Wish I could save more places", "page": "/explore", "user_ref": "42" }
```

## Responses and protection (both endpoints)

| Case | Status | Body |
|---|---|---|
| Saved | `201` | `{"data": {"id": 7, "created_at": "…"}, "meta": null, "error": null}` |
| Invalid | `422` | `error.code: "validation_error"`, `error.details.errors: [{loc: ["body", "<field>"], msg, type}]` |
| More than 5 in 10 minutes from one IP | `429` | `error.code: "rate_limited"` |
| Hidden `website` field filled in (a bot) | `201` | `data: null`; nothing is saved |

Browsers may call these from the origins in `config/sites.yml`, `https://lyndbergh.net`, and `localhost:3000-3004`.

## Event log

Every app writes one JSON line per event to its normal logs, so a person's path can be followed
across apps by `session_id`. Reference implementation: `app/models/event_log.rb`.

| Field | Example | Notes |
|---|---|---|
| `ts` | `2026-11-18T17:40:12.311Z` | UTC, milliseconds |
| `app` | `real-calc` | the `config/sites.yml` slug |
| `env` | `production` | |
| `event` | `request`, `page_view`, `contact_submitted`, `feedback_submitted`, `signed_in` | `noun_verb` |
| `session_id` | `s_8f3c…` | random per browser session (sessionStorage), sent as the `X-Session-Id` header; not a cookie or fingerprint |
| `user_id` | `42` or `null` | the app's own id, only when signed in |
| `request_id` | `b1e2…` | ties an event to its request |
| `method`, `route`, `status`, `duration_ms` | `GET`, `/api/items/:state/:city`, `200`, `41.2` | `request` events; `route` is the pattern, never the real URL |
| `props` | `{"site": "real-calc", "rating": 4}` | small and event-specific |

**Never log** emails, names, message or comment text, query strings, tokens or request bodies.

A flow reads like: `page_view /` → `page_view /explore` → `request GET /api/rank-locations` →
`feedback_submitted {"rating": 4}`, all with the same `session_id`.
