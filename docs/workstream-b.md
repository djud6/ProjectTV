# Workstream B: Live & Social

**Assigned to:** _(name)_ · **Branch prefix:** `b/` · **Feature folders:** `events`, `rooms`,
`creators`, `polls`, `social`, `notifications` · also owns `src/components/ui/` and the app shell.

**Mission:** fans and creators gather around an episode: schedule a watch party, share the link,
chat live, vote in polls, follow the hosts they like. Everything stays inside SceneLock.

Read first: [AGENTS.md](../AGENTS.md), [architecture.md](architecture.md),
[contracts.md](contracts.md). Every content table you create follows **contract §1** (boundary
columns + SceneLock RLS policy). No exceptions.

Tasks are in dependency order. Items marked **⇠ A** depend on Workstream A; build against seed data
or a stub until then. Each task is done when its acceptance check passes and has a test.

---

## B0. App shell & UI kit (start here; A benefits too)

- [ ] Root layout: header with logo, nav (Shows, Events, Profile), auth-aware menu, mobile nav;
      light/dark tokens in `globals.css`
- [ ] `src/components/ui`: Button, Input, Textarea, Select, Dialog, Card, Tabs, Avatar, Badge, Toast,
      EmptyState, Skeleton. Accessible (labels, focus rings, keyboard).
- [ ] Time-zone helpers: store UTC, render in the viewer's zone, show the zone explicitly
- [ ] "Unofficial fan community" footer label (no implied show affiliation)

## B1. Events & RSVP

- [ ] `events` table per contract §1, plus host_id, episode_id, title, description, starts_at
      (UTC), host time zone, visibility (`public`/`private`), capacity, spoiler mode
      (`first_watch`/`rewatch`), `invite_token`, status (`scheduled`/`live`/`ended`/`cancelled`)
- [ ] Only `creator`/`moderator`/`admin` can create **public** events; anyone can create private ones
      (contract §6)
- [ ] Create/edit/cancel/reschedule; cancelled events stay visible as cancelled
- [ ] Private events reachable only via the invite link **and** still subject to SceneLock and
      blocking (PRD test 6)
- [ ] `rsvps` table; RSVP / un-RSVP; RSVP ≠ attendance
- [ ] Events calendar `/events`: upcoming public events filtered by SceneLock, by show, in the
      viewer's time zone
- [ ] Event titles/descriptions are host-written content, so they go through A's screening when it
      exists ⇠ A4. Until then events default to the episode's boundary.
- [ ] `rewatch` rooms are shown with a clear warning and excluded from protected feeds
- **Accept:** a host schedules, shares a link, and an invitee RSVPs from a phone browser.

## B2. Rooms & live chat

- [ ] Write a short design note in decisions.md first: room position model, Postgres Changes vs
      Broadcast, reconnect behaviour, rate limits
- [ ] `room_participants` (event_id, user_id, role `host`/`cohost`/`guest`, joined_at, left_at,
      muted_until, banned)
- [ ] `chat_messages` per contract §1. Boundary = the room's current position when sent (first-watch
      rooms) or the event boundary (rewatch rooms).
- [ ] Host sets/advances the room position ("we're at 15:00 in E5"); participants opt in to the room
      position while inside the room. Their saved show progress doesn't change (contract §3).
- [ ] Join/leave, presence list (Presence carries ids only, never message content)
- [ ] Realtime chat via Postgres Changes (RLS-filtered). History/reconnect via RLS-scoped query, so
      no locked replay (PRD test 11).
- [ ] Host controls: pause chat, mute, remove, ban (removed/banned can't rejoin, PRD test 8), close
      room; each writes `audit_events`
- [ ] Per-user chat rate limit; message length cap; `<ReportButton targetType="chat_message">` ⇠ A5
- [ ] Graceful reconnect UI; "room ended" state then `<ProgressPrompt>` ⇠ A2
- [ ] Load test: script N simulated clients in one room (agree N with the founder), measure delivery
      latency and failures; record results in decisions.md
- **Accept:** two+ clients exchange messages reliably; a participant behind the room position never
  receives later messages.

## B3. Polls

- [ ] `polls`, `poll_options` (each with its own boundary, since options can reveal future
      contestants), `poll_votes` (unique per user per poll)
- [ ] Episode-scoped polls on episode pages and inside rooms; creator/host can close a poll
- [ ] Results are spoiler-safe: store result snapshots keyed by boundary (or count only votes cast
      by viewers at or before the reader's progress). A viewer must never see results influenced by
      people further ahead (PRD test 5).
- [ ] Options/titles are screened like other content ⇠ A4
- [ ] Register `poll` / `poll_option` in the moderation registry ⇠ A5
- **Accept:** PRD test 5.

## B4. Social: follows, creator pages, Watch With Me

- [ ] `follows` (follower_id, followee_id); follow/unfollow; respect `is_private` and blocks
- [ ] Following feed: upcoming public events from people you follow (SceneLock-filtered)
- [ ] Creator page `/c/[username]`: bio, branding (`creator_pages` table), upcoming events, shareable
      URL
- [ ] Watch With Me (basic): "find a room for the episode I'm about to watch": public first-watch
      events for the viewer's next episode, soonest first. No 1:1 matching or stranger contact.

## B5. Notifications

- [ ] `notifications` table + `notify()` helper with `canView` check (contract §7)
- [ ] In-app notification list; opt-in event reminders (e.g. 15 min before) via a scheduled job
      (Supabase cron or Vercel cron)
- [ ] Email reminders only if an email provider is chosen; subjects contain no spoiler text
- [ ] Leak tests: a notification about locked content is never created or sent

## B6. Launch readiness (with A)

- [ ] Write leak-suite cases for events, chat, polls, feeds, notifications (A owns the suite)
- [ ] Mobile performance pass (Lighthouse on show, event and room pages)
- [ ] Register `chat_message`, `poll`, `poll_option`, `event`, `room` in the moderation registry
- [ ] Instrument `event_created`, `rsvp`, `room_joined`, `chat_sent`, `poll_voted`, `follow`
