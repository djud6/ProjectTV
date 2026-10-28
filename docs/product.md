# Product overview

Condensed from the founding documents (Scope & PRD, Roadmap deck, PRD v1.0, October 2026). Those
are planning drafts: features, dates and prices are proposals, not commitments. Drop the original
PDFs into `docs/source/` if you want them in the repo.

## One-liner

The social layer of TV and film. React to what you've watched, find your people, and never see a
spoiler for something you haven't watched yet.

## Boundaries

- Responsive, mobile-first **web app**. Native apps only once demand is proven.
- **No video.** Viewers stream through their own legal provider; SceneTalk is the companion.
- Start with **a few reality-TV fandoms**, invite-only, at controlled capacity. Then scripted TV,
  K-dramas, movies. The data model must support all of them from day one (editions/cuts, specials,
  odd numbering, movies).
- Safety and moderation from day one. Spoiler protection is free forever, never a paid feature.

## Personas

| Persona | Job to be done |
|---|---|
| First-time viewer | Discuss only what they've watched without seeing what's coming |
| Live reality-TV fan | Join episode conversations, polls and watch parties as episodes air |
| Creator / host | Schedule a branded room, invite followers, moderate it |
| Watch With Me viewer | Find a public room for the episode they're about to watch |
| Moderator | Respond quickly to spoiler, abuse and safety reports |

## Core journeys (beta)

- **Viewer:** sign up → choose shows → set progress → read/post permitted comments → vote in polls →
  follow a host → RSVP and join a watch party.
- **Creator/host:** get approved as creator → profile → schedule room → share link → host live chat →
  moderate → see attendance.
- **Moderator:** see report → inspect content and its spoiler boundary → hide, remove, reclassify or
  restore → audit trail.

## Beta scope (stage 1)

P0: accounts & profiles · show/season/episode catalog · SceneLock progress & filtering ·
episode/scene discussions · moderation, reports & blocking · scheduled watch-party rooms with live
chat.
P1: polls · follow creators/users · basic Watch With Me (browse episode-matched public rooms) ·
shareable creator room pages · basic analytics.

Explicitly **not** in the beta: friends, DMs, payments/subscriptions/ads, external social reaction
aggregation, AI matching, fantasy/prediction leagues, synchronized playback, official show
affiliation claims (label everything as fan-made/unofficial).

## If capacity slips

Cut in this order: Watch With Me → follows feed polish → poll extras → creator page branding.
Never cut SceneLock enforcement, reporting/blocking or moderation.

## Later stages (context only, do not build yet)

- **Stage 2, engagement:** friends, watch tracker, Watch With Me matching, host countdown cues,
  aftershows, popularity rankings, prediction leagues, fan awards, fandom clubs, "SceneTalk Tonight"
  guide, spoiler-safe recommendations.
- **Stage 3, expansion:** consent-based DMs, links to permitted external reactions, "Time Travel"
  reactions, fantasy reality TV, personality profile, advanced matching filters, Creator Studio,
  contextual ads, SceneTalk Plus (ad-free, ~$3.99/mo hypothesis).
- **Stage 4, partnerships:** sponsored hubs, branded polls, ticketed creator events, aggregated
  sponsor insights, creator paid tier, streaming affiliate links.

What this means for beta design: keep `editions`, `roles` and the generic spoiler-boundary columns
flexible enough for these. Don't build anything for them yet.

## Success metrics

- Activation: % of invited users who set progress **and** join a discussion or event.
- Engagement: RSVP→attendance, comments/votes per attendee, weekly returning viewers.
- Creator value: hosts who schedule a second event, repeat attendees per host.
- Safety: confirmed spoiler leaks (target: zero known), median report resolution time.

## Go / no-go for inviting people

No known spoiler bypasses · report/block/moderation working · scheduling and mobile room joins work
· realtime tested at the agreed room size · backups tested · creator support owner assigned ·
name/IP checks done · legal pages (terms, privacy, community rules) published.
