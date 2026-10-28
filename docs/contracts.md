# Cross-workstream contracts

These are the only places Workstream A (Content & Safety) and Workstream B (Live & Social) depend on
each other. Changing anything here needs the other developer's review. When a contract is
implemented, change its status from **planned** to **ready** and link the code.

---

## 1. Spoiler-boundary columns on every content table (both) — ready

Every table holding user-visible content (comments, chat messages, polls, poll options, events,
rooms, and anything later) includes:

```sql
show_id            uuid not null references public.shows (id),
spoiler_edition_id uuid references public.editions (id),
spoiler_episode    int  not null check (spoiler_episode >= 0),
spoiler_seconds    int  check (spoiler_seconds >= 0),
status             public.content_status not null default 'pending',
author_id          uuid references public.profiles (id) on delete set null,
```

…and this SELECT policy shape (adapt the author/owner column):

```sql
create policy "scenelock read" on public.<table> for select using (
  (status = 'published'
     and public.scenelock_visible(show_id, spoiler_edition_id, spoiler_episode, spoiler_seconds)
     and not public.is_blocked_between(auth.uid(), author_id))
  or author_id = auth.uid()
  or public.is_moderator()
);
```

Content that needs no review may be inserted as `published` by server code. Content that fails
screening stays `pending` or `quarantined`.

## 2. SceneLock functions (A owns) — ready

- SQL: `public.scenelock_visible(show, edition, episode, seconds)` and
  `public.scenelock_can_view(viewer, …)`.
- TS: `canView(progress, boundary)` in `src/lib/scenelock/visibility.ts`.
- **For B:** to check a list of users server-side (e.g. notification fan-out), load their
  `viewer_progress` rows with the service client and call `canView` for each.

## 3. Progress (A owns) — planned

- A provides `setProgress({ showId, editionId, episode, positionSeconds, episodeCompleted })`
  as a Server Action in `src/features/progress/actions.ts`, plus a `<ProgressPrompt showId>` client
  component asking the user to confirm a progress update.
- **B never writes `viewer_progress`.** When a watch party ends, B shows `<ProgressPrompt>` so the
  user can confirm "I've finished E5".
- B's room position (where the room currently is during a live party) is B's own data and lives in
  B's tables.

## 4. Blocking (A owns) — ready (SQL) / planned (UI)

- `public.is_blocked_between(a, b)` is available now. B must use it for room joins, chat visibility,
  follows, RSVPs on someone's event and poll comments.
- A builds the block/unblock UI and `blockUser(userId)` action.

## 5. Reports & moderation (A owns; B registers targets) — planned

- A creates `reports` and the RPC/Server Action
  `reportContent({ targetType, targetId, kind: 'spoiler' | 'abuse' | 'spam' | 'other', note })`, plus
  a reusable `<ReportButton targetType targetId />`.
- Target types: `comment`, `profile` (A) and `chat_message`, `poll`, `poll_option`, `event`, `room`
  (B).
- A maintains a registry in `src/features/moderation/targets.ts` mapping each target type to its
  table and preview fields. **B adds entries for B's tables via PR.** Since every content table
  follows contract §1, the moderation console can hide/remove/restore/reclassify generically by
  updating `status` and the boundary columns, then writing `audit_events`.
- "Report spoiler" immediately hides the item from the reporter. A threshold, or a moderator, hides
  it for everyone (`quarantined`).
- Room-level host actions (mute, remove, ban) are B's and must write `audit_events` with
  `action = 'room.*'`.

## 6. Profiles, roles and creator approval (A owns) — ready (schema) / planned (UI)

- B reads `profiles.role`. Only `creator`/`moderator`/`admin` can host public events.
- Creators are approved manually during the beta. A's admin page sets `role = 'creator'`.
- B owns the public creator page (`/c/[username]`) and its branding fields. B adds those columns to
  a separate `creator_pages` table rather than to `profiles`.

## 7. Notifications (B owns) — planned

- B creates `notifications` and the server-only helper
  `notify({ userId, kind, payload, boundary })` in `src/features/notifications/notify.ts`.
- `notify` runs `canView` against the recipient's progress before inserting or sending, and never
  includes spoiler text in email/push subjects.
- A calls `notify` for reply/mention/moderation-outcome notifications. Those are optional for the
  beta.

## 8. Shared UI (B owns) — planned

- B sets up the app shell (header/nav, auth-aware menu) and primitives in `src/components/ui`
  (Button, Input, Textarea, Dialog, Card, Tabs, Avatar, Badge, Toast, EmptyState) early, so A doesn't
  invent parallel ones.
- Until those exist, A uses plain Tailwind in feature folders and switches later.

## 9. Analytics (A owns helper; each instruments own features) — planned

- A creates `analytics_events` (no PII beyond user id) and `track(name, props)`.
- Event names: `signup`, `progress_set`, `comment_created`, `report_created` (A) and
  `event_created`, `rsvp`, `room_joined`, `chat_sent`, `poll_voted`, `follow` (B).
