# SceneTalk

The spoiler-safe social layer for TV and film: scene-level discussions, fan polls, watch parties and
creator rooms. Viewers watch on their own streaming service, and SceneTalk is the companion.

**Start with [AGENTS.md](AGENTS.md).** It explains the product, the two workstreams, the rules,
and how humans and coding agents (Claude Code, Codex) coordinate in this repo.

## Quick start

Requires Node 20+ and Docker (for local Supabase).

```bash
npm install
npm run db:start                # prints local URL + keys
cp .env.example .env.local      # paste the anon + service-role keys
npm run dev                     # http://localhost:3000
npm run check                   # lint + typecheck + unit tests
npm run test:db                 # database tests incl. SceneLock
```

## Docs

- [Product overview](docs/product.md): what we're building and what we're not
- [Architecture](docs/architecture.md): stack, data model, SceneLock, realtime
- [Workstream A: Content & Safety](docs/workstream-a.md)
- [Workstream B: Live & Social](docs/workstream-b.md)
- [Contracts](docs/contracts.md): the interfaces between A and B
- [Decisions & open questions](docs/decisions.md)
- [Hand-offs](docs/handoffs.md)
