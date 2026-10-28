# SceneTalk: instructions for humans and coding agents

This file is the entry point for anyone working in this repo, whether you are a person, Claude Code
(which loads it via `CLAUDE.md`) or Codex (which reads `AGENTS.md` directly). Read it fully before
changing anything.

## What we are building

SceneTalk is a spoiler-safe social companion for TV and film: scene-level discussions, fan polls,
scheduled watch parties with live chat, and creator-hosted rooms. Viewers watch on their own
streaming service; **we never host or stream video.** The first audience is reality-TV fans, with a
small invite-only private beta. The full picture is in [docs/product.md](docs/product.md).

The one thing that must never break is **SceneLock**: a viewer never receives content that spoils
anything past their own progress in a show. That covers comments, chat, polls, event titles, search,
notifications, previews and feeds. See [docs/architecture.md](docs/architecture.md#scenelock).

## Two workstreams

The beta is split into two vertical slices. Each developer (and their agent) owns their features
end to end: schema, RLS, server code, UI and tests.

| Workstream | Theme | Plan | Owns |
|---|---|---|---|
| **A** | Content & Safety | [docs/workstream-a.md](docs/workstream-a.md) | accounts, catalog, progress, discussions, spoiler screening, reports & moderation, blocking, search, SceneLock core |
| **B** | Live & Social | [docs/workstream-b.md](docs/workstream-b.md) | app shell & UI kit, events & RSVP, rooms & realtime chat, creator pages, polls, follows, Watch With Me browse, notifications |

The two slices touch only through the interfaces in [docs/contracts.md](docs/contracts.md). If you
need something from the other workstream that isn't there, add a request to
[docs/handoffs.md](docs/handoffs.md) rather than building it in their area.

## If you are an agent starting a session

1. Ask (or infer from the branch name `a/...` or `b/...`) which workstream you are working on.
2. Read your workstream doc, [docs/contracts.md](docs/contracts.md) and the open entries in
   [docs/handoffs.md](docs/handoffs.md).
3. Pick the first unchecked task in your workstream doc whose dependencies are met. Prefer finishing
   a milestone to starting a new one.
4. When you finish a task, tick its checkbox in the same PR, and note any contract change in
   `docs/contracts.md` and any decision in [docs/decisions.md](docs/decisions.md).
5. Planning dates in the source docs are aspirational, not deadlines. Don't cut SceneLock or safety
   work to hit a date; cut scope instead (see "If capacity slips" in docs/product.md).

## Non-negotiable rules

- **Deny by default.** Every content table carries a spoiler boundary and a `status`, and its SELECT
  RLS policy calls `public.scenelock_visible(...)` and requires `status = 'published'` (authors and
  moderators may see their own pending items). No exceptions. See docs/contracts.md §1.
- **Filter on the server, not in CSS.** Never send locked content to the browser and blur it. Avoid
  spoilers in URLs, slugs, page titles, OG metadata and notification payloads.
- **The service-role client bypasses RLS and SceneLock.** Use `createServiceClient()` only for
  admin, moderation or background jobs, and run `canView()` on anything that reaches a user.
- **Progress only moves when the user explicitly confirms it.** Opening a page, joining a room or
  voting never advances `viewer_progress`.
- **Don't weaken the SceneLock tests** (`supabase/tests/scenelock_test.sql`,
  `src/lib/scenelock/visibility.test.ts`). Add cases; changing an expectation needs both developers
  to agree and a note in docs/decisions.md.
- Every new surface that shows user content gets a leak test: a viewer behind the boundary can't
  retrieve it through that surface.
- Blocking is enforced in both directions wherever users interact (`public.is_blocked_between`).
- Out of scope for the beta, so don't build: DMs, payments/subscriptions/ads, native apps,
  scraping external social sites, fantasy leagues, AI matching, video sync/redistribution.

## Repo layout

```
supabase/
  migrations/      SQL migrations (append-only; see "Shared files")
  tests/           pgTAP tests run by `npm run test:db`
  config.toml      local Supabase config
src/
  app/             Next.js App Router routes (route folders belong to the feature owner)
  features/<name>/ feature code; README in each says which workstream owns it
  components/ui/   shared UI primitives (Workstream B owns, A may add)
  lib/scenelock/   TS mirror of the SceneLock rule (Workstream A owns)
  lib/supabase/    Supabase clients (shared)
  types/database.ts  generated DB types (never hand-edit; run `npm run db:types`)
docs/              product, architecture, workstreams, contracts, decisions, handoffs
```

## Shared files and avoiding collisions

- **Migrations:** new files only, never edit a migration that is on `main`. Name them
  `YYYYMMDDHHMMSS_<a|b>_<topic>.sql` (`npx supabase migration new a_comments` then rename). If both
  workstreams change the same table, the owner writes the migration.
- **`src/types/database.ts`:** on a merge conflict, take either side and rerun `npm run db:types`.
- **`src/lib/scenelock/`, the foundation migration, `docs/contracts.md`:** changes need a review
  from the other developer.
- **`src/components/ui/`:** additive changes are fine; changing an existing component's API means
  tagging the other developer.

## Git workflow

- Branches: `a/<topic>` or `b/<topic>`, short-lived, PR into `main`.
- PRs touching shared files (above) need the other developer's review. Other PRs may self-merge once
  `npm run check` passes, but a quick cross-review is encouraged.
- Optional: ask the other agent (Codex or Claude) to review any PR touching SceneLock, RLS or
  moderation. A second model catches different mistakes.

## Commands

```bash
npm install
cp .env.example .env.local     # fill from `npm run db:start` output
npm run db:start               # local Supabase (needs Docker)
npm run db:reset               # re-apply migrations + seed
npm run db:types               # regenerate src/types/database.ts
npm run dev                    # http://localhost:3000
npm run check                  # lint + typecheck + unit tests (run before every PR)
npm run test:db                # pgTAP tests incl. SceneLock (needs db:start)
```

## Conventions

- TypeScript strict; validate all input at the server boundary with `zod`.
- Server Components and Server Actions by default; client components only for interactivity and
  realtime.
- Mobile-first layouts; keyboard-accessible forms with labels.
- Keep comments sparse and explain *why*. Match the style of surrounding code.
