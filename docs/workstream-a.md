# Workstream A: Content & Safety

**Assigned to:** _(name)_ · **Branch prefix:** `a/` · **Feature folders:** `accounts`, `catalog`,
`progress`, `discussions`, `moderation`, `search` · also owns `src/lib/scenelock/` and the
foundation migration.

**Mission:** a viewer can sign up, say where they are in a show, and talk about it without ever being
spoiled, and the team can act quickly when something goes wrong. You own the product's core promise.

Read first: [AGENTS.md](../AGENTS.md), [architecture.md](architecture.md),
[contracts.md](contracts.md).

Tasks are in dependency order. Items marked **⇢ B** unblock Workstream B, so do them early. Each task
is done when its acceptance check passes and has a test (pgTAP for RLS/SQL, vitest for logic).

---

## A0. Foundation hand-off ⇢ B

- [x] Foundation migration: profiles, catalog, progress, SceneLock functions, blocks, audit log
- [x] SceneLock pgTAP + vitest suites (18 + 17 cases)
- [ ] Run `npm run db:start && npm run test:db` on a machine with Docker and confirm the pgTAP suite
      passes against real Supabase. It was only verified in PGlite with stubbed `auth`.
- [ ] `supabase/seed.sql`: one reality show with 2 editions, 2 seasons, ~10 episodes (incl. a
      special), plus 4 test users (mid-season, not started, finished, moderator) ⇢ B
- [ ] Generate `src/types/database.ts` and commit ⇢ B

## A1. Accounts & onboarding ⇢ B

- [ ] Sign up / sign in / sign out (email + one social provider), auth callback route ⇢ B
- [ ] Onboarding: pick username (replace placeholder), choose favourite shows, set progress per show
      (default "not started"); set `onboarded_at`
- [ ] Profile page `/u/[username]` and edit settings (display name, avatar upload to Storage, bio,
      private toggle). Private profiles hide activity from non-followers.
- [ ] Minimum age gate at signup (age decided by founder; see decisions.md)
- [ ] Account deletion: delete auth user → cascade/anonymize per the privacy policy; export own data
      as JSON
- **Accept:** a new user can go from signup to a show page with progress set, on a phone-width
  screen.

## A2. Catalog & progress ⇢ B

- [ ] Show page `/shows/[slug]`: seasons and episodes in `episode_order`. **Episode titles past the
      viewer's progress are hidden** (show the `display_code` only).
- [ ] Admin catalog tooling (moderator/admin only): create/edit shows, editions, seasons, episodes,
      with a source/attribution field. A CSV/JSON import script is fine for the beta.
- [ ] `setProgress` Server Action + `<ProgressPrompt>` component (contract §3) ⇢ B
- [ ] Progress UI: "I'm on E5 at 23:10" or "I finished E5", with a choice of edition. Moving forward
      asks for confirmation; moving back is allowed.
- [ ] Progress change revalidates the viewer's cached pages
- **Accept:** PRD test 9: change progress, and no stale page or feed shows newly locked content.

## A3. Discussions

- [ ] `comments` table per contract §1, plus `episode_id`, optional `scene_seconds`, `parent_id`,
      `body`, `edited_at`; RLS policies; rate limit on insert
- [ ] Episode discussion page: thread list for the episode, optional timestamp anchor ("at 23:10"),
      replies (inherit boundary), sort by time-in-episode / newest
- [ ] Author can raise the boundary ("contains spoilers up to E7")
- [ ] Edit sends the comment back to `pending` until re-screened; delete is a soft delete
- [ ] Sanitize/escape all user text; no raw HTML
- **Accept:** PRD tests 1, 2 and 4 through the comments API, direct link and SSR page.

## A4. Spoiler screening

- [ ] Server-side screener runs on create/edit: detects references to later episodes (episode
      codes like "E10"/"episode 10"/"finale", plus an admin-managed per-episode **spoiler term list**,
      e.g. names of contestants who join or leave later). Hits are raised to the right boundary or
      `quarantined`.
- [ ] Unscreened or uncertain content is never `published`
- [ ] Keep it rule-based for the beta; an LLM classifier is a later, optional add-on
- **Accept:** PRD test 3: a comment tagged E2 that mentions E10 is held, and a moderator can
  reclassify it.

## A5. Reports, moderation, blocking

- [ ] `reports` table, `reportContent` action, `<ReportButton>` (contract §5) ⇢ B
- [ ] `src/features/moderation/targets.ts` registry with `comment` and `profile` ⇢ B
- [ ] Moderation console `/mod`: queue by age/severity, preview with boundary, actions (hide,
      remove, restore, reclassify boundary, warn/suspend user), resolution notes; every action writes
      `audit_events`
- [ ] Appeals: the author of removed content can request review once (simple form → queue)
- [ ] Block/unblock UI and action; blocked users' content is hidden both ways in A's surfaces
- [ ] Suspended users can't post (RLS or insert check)
- **Accept:** PRD tests 7 and 10; a "report spoiler" hides the item for the reporter immediately.

## A6. Search & previews

- [ ] Search shows/episodes/comments via the RLS-scoped client only. Autocomplete must not suggest
      locked episode titles or comment text.
- [ ] Share links and OG metadata for shows/comments contain no spoilers (episode code only;
      comment text only if boundary = 0)
- [ ] Signed-out visitors see show-level content only

## A7. Safety & launch readiness (A leads, B contributes)

- [ ] **Cross-surface leak suite:** for each surface in architecture.md's enforcement table, a test
      where a viewer behind the boundary tries API, direct link, search, notification and realtime.
      B writes the cases for B's surfaces; A owns the suite and the CI job.
- [ ] Rate limits and basic anti-spam on signup/post/report
- [ ] Legal/policy pages: Terms, Privacy, Community Guidelines, report contact (text from the
      founder; you build the pages)
- [ ] `analytics_events` + `track()` (contract §9)
- [ ] Backup/restore drill on the staging project; written incident checklist
- [ ] Security pass: authz on every Server Action, no service-role key in client bundles, input
      validation, CSP basics
