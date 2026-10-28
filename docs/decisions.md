# Decisions & open questions

Append new decisions at the bottom of their section with the date and who made them. If you reverse
a decision, strike it through and add the new one; don't delete history.

## Decided

| Date | Decision | Why |
|---|---|---|
| 2026-10-28 | Stack: Next.js 15 + TypeScript + Tailwind, Supabase (Postgres/Auth/Realtime/Storage), Vercel | Suggested by the PRD. RLS lets SceneLock be enforced in the database. |
| 2026-10-28 | Work split into two **vertical** workstreams (A: Content & Safety, B: Live & Social) | Each developer owns features end to end, so there are fewer hand-offs. Interfaces are in contracts.md. |
| 2026-10-28 | Both developers may use Claude Code or Codex. `AGENTS.md` is canonical; `CLAUDE.md` imports it. | One source of truth for both agents. |
| 2026-10-28 | SceneLock is a SQL function used in RLS; `canView` in TS mirrors it | The database enforces it on every query, including realtime. |
| 2026-10-28 | No progress row = "not started" = only show-level (episode 0) content visible. Signed out is the same. | Deny by default. |
| 2026-10-28 | Timestamps are only compared within the same edition; otherwise the episode is treated as whole | The PRD prefers episode-level gating until cuts are mapped. |
| 2026-10-28 | Proposed: **episode-level progress is the default UX**, and timestamps are optional per post/room. Full timestamp precision only for curated editions. | Answers the PRD's open question pragmatically. Founder to confirm. |
| 2026-10-28 | Creators are approved manually during the beta (admin sets role) | Recommended in the PRD. |
| 2026-10-28 | Planning dates are aspirational; scope is cut before safety | Founder guidance. |

## Open questions (founder / team)

- [ ] Who is assigned to Workstream A and who to B? (Fill in the top of each workstream doc.)
- [ ] Weekly hours each developer can commit, and the hosting budget.
- [ ] Which reality-TV shows and regions first? Is there a confirmed January 2027 schedule?
- [ ] Catalog source: hand-entered, or an API (e.g. TMDB/TVmaze)? Check licence/attribution terms.
- [ ] Minimum age for accounts, and safeguards for minors.
- [ ] Target concurrent users per room for the load test, and the max number of concurrent rooms.
- [ ] Who handles moderation shifts, incidents and creator support during the beta?
- [ ] Social login provider(s): Google? Apple? Discord?
- [ ] Email provider for reminders (or in-app only for the beta).
- [ ] Ownership/equity/IP assignment between the founders, documented before outside users join.
- [ ] Trademark/domain check on "SceneTalk".
