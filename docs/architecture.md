# Architecture

## Stack (decided)

- **Next.js 15** (App Router) + TypeScript + Tailwind v4, deployed on **Vercel**.
- **Supabase**: Postgres, Auth, Realtime, Storage (avatars). RLS is the main enforcement point.
- `zod` for input validation, `vitest` for unit tests, pgTAP (`supabase test db`) for database tests.
- To add when needed: Sentry (errors), a transactional email provider (reminders).

## Data model

Already in `supabase/migrations/20261028000000_foundation.sql` (applies to both workstreams):

| Table / function | Purpose |
|---|---|
| `profiles` | 1:1 with `auth.users`; username, privacy flag, `role` (`user`/`creator`/`moderator`/`admin`). Users cannot change their own role. |
| `shows`, `editions`, `seasons`, `episodes` | Catalog. `episodes.episode_order` is the normalized, show-wide order SceneLock compares. `editions` are cuts/versions. |
| `viewer_progress` | One row per (user, show). No row means "not started". |
| `scenelock_can_view(viewer, show, edition, episode, seconds)` | The visibility rule. |
| `scenelock_visible(show, edition, episode, seconds)` | Same rule for `auth.uid()`; use it in RLS. |
| `blocks`, `is_blocked_between(a, b)` | Two-way block check. |
| `audit_events` | Who changed what and why (moderation, reclassification, room bans). |
| `current_app_role()`, `is_moderator()` | Role helpers for policies. |

Each workstream adds its own tables. The planned owners are listed in the workstream docs.

## SceneLock

### The rule

Content carries a **spoiler boundary**: the latest point in the show it may spoil.

```
show_id, spoiler_edition_id, spoiler_episode, spoiler_seconds
```

A viewer may see it only if all of these hold:

1. the content is `published`, **and**
2. `spoiler_episode = 0` (show-level, no episode spoilers), **or**
3. `spoiler_episode < viewer.episode_order`, **or**
4. same episode **and** (viewer marked the episode completed **or** `spoiler_seconds <=
   viewer.position_seconds`).

Additional rules:

- `spoiler_seconds IS NULL` means "spoils the whole episode", so the viewer must have completed it.
- Timestamps only compare within the **same edition**. A timestamp from another edition, or with no
  edition, is treated as whole-episode. This is the PRD's "prefer episode-level gating until cuts
  are mapped".
- No progress row, or signed out: only `spoiler_episode = 0` is visible.
- Any null/invalid boundary: denied.

The SQL function is canonical. `src/lib/scenelock/visibility.ts` (`canView`) mirrors it for code
paths outside the database. Both have matching test suites.

### Where the boundary comes from

The location of a post is **not** proof it's spoiler-free. A comment on E2 can mention E10.

- Default boundary = where it was posted (episode and optional timestamp). Replies inherit the
  parent's boundary unless they declare a later one.
- Authors can raise the boundary manually ("this spoils up to E5").
- Server-side screening (Workstream A) can hold content as `pending`/`quarantined` when it looks like
  it references later episodes.
- Moderators can reclassify the boundary; every change is written to `audit_events`.
- Editing published content sends it back through screening.

### Enforcement points (every one needs a leak test)

| Surface | Mechanism | Owner |
|---|---|---|
| Comments, replies, threads | RLS on table | A |
| Search & autocomplete | Query through RLS-scoped client only; no separate unfiltered index | A |
| Episode titles / catalog cards | API returns titles only up to viewer progress (catalog RLS is public, so filter in the API) | A |
| Poll questions, options, results | RLS + per-boundary result snapshots | B |
| Event / room titles, descriptions, cards | RLS on events; event boundary set by host | B |
| Live chat (incl. reconnect replay) | Realtime + RLS; see "Realtime" below | B |
| Notifications, emails, OG previews, share links | `canView()` check at send/render time | B (notifications), A (share previews of comments) |
| Feeds (following, Watch With Me) | Built from RLS-scoped queries | B |

### Caching

Never cache personalized, boundary-filtered responses across users. When progress changes,
revalidate the viewer's cached pages (`revalidatePath`/`revalidateTag`) and have realtime clients
resubscribe.

## Realtime

Supabase Realtime **Postgres Changes** respects RLS per subscriber, so chat rows inserted into
`chat_messages` with a boundary are only delivered to participants allowed to see them. That gives
us SceneLock in chat without a custom server. For the beta's room sizes this is enough. Workstream B
owns load-testing it and choosing Broadcast + server-side filtering if it doesn't scale. Never use
Broadcast/Presence to send message *content* unless it has been filtered server-side.

Reconnect and history load go through the same RLS-scoped query, so locked messages are never
replayed.

## Auth

Email (magic link or password) plus one social provider. Middleware refreshes the session
(`src/middleware.ts`). Each feature protects its own routes. Server code gets the user from
`supabase.auth.getUser()`, never from client-sent IDs.

## Environments

- **Local:** `npm run db:start` (Docker). Seed data in `supabase/seed.sql` (Workstream A creates it).
- **Staging/prod:** two Supabase projects + Vercel preview/prod. Migrations are applied with
  `supabase db push` from `main` only.
- Secrets live only in `.env.local` / Vercel env. The service-role key is never exposed to the
  browser.
