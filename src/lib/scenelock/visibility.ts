// TypeScript mirror of public.scenelock_can_view (supabase/migrations/*_foundation.sql).
// The SQL function is the source of truth and is what RLS enforces. Use this only where a check
// has to happen outside a query: before broadcasting realtime payloads, building notifications,
// emails or share previews. If you change one, change both and keep both test suites in sync.

export type SpoilerBoundary = {
  showId: string | null;
  editionId: string | null;
  /** 0 = show-level, no episode spoilers. */
  episode: number | null;
  /** null = spoils the whole episode. Only comparable within the same edition. */
  seconds: number | null;
};

export type ViewerProgress = {
  showId: string;
  editionId: string | null;
  /** 0 = not started. */
  episode: number;
  positionSeconds: number;
  episodeCompleted: boolean;
};

/**
 * Deny-by-default visibility check. `progress` is the viewer's row for `boundary.showId`, or null
 * when the viewer is signed out or has not started the show.
 */
export function canView(progress: ViewerProgress | null, boundary: SpoilerBoundary): boolean {
  const { showId, editionId, episode } = boundary;
  if (showId === null || episode === null || episode < 0) return false;
  if (progress !== null && progress.showId !== showId) return false;

  if (progress === null) return episode === 0;
  if (episode === 0) return true;

  const seconds =
    boundary.seconds !== null && editionId !== null && editionId === progress.editionId
      ? boundary.seconds
      : null;

  if (episode < progress.episode) return true;
  if (episode === progress.episode) {
    return progress.episodeCompleted || (seconds !== null && seconds <= progress.positionSeconds);
  }
  return false;
}
