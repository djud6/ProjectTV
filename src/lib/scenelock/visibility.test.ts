// Mirrors supabase/tests/scenelock_test.sql case for case.
import { describe, expect, it } from "vitest";
import { canView, type ViewerProgress } from "./visibility";

const show = "show";
const broadcast = "broadcast";
const streamer = "streamer";

const mid: ViewerProgress = {
  showId: show,
  editionId: broadcast,
  episode: 2,
  positionSeconds: 600,
  episodeCompleted: false,
};
const done: ViewerProgress = { ...mid, positionSeconds: 0, episodeCompleted: true };

const b = (editionId: string | null, episode: number | null, seconds: number | null, showId: string | null = show) => ({
  showId,
  editionId,
  episode,
  seconds,
});

describe("canView: viewer at E2 10:00", () => {
  it("shows E1 whole-episode content", () => expect(canView(mid, b(broadcast, 1, null))).toBe(true));
  it("shows E2 10:00", () => expect(canView(mid, b(broadcast, 2, 600))).toBe(true));
  it("hides E2 10:01", () => expect(canView(mid, b(broadcast, 2, 601))).toBe(false));
  it("hides E2 whole-episode until completed", () => expect(canView(mid, b(broadcast, 2, null))).toBe(false));
  it("hides E3", () => expect(canView(mid, b(broadcast, 3, 0))).toBe(false));
  it("shows show-level content", () => expect(canView(mid, b(null, 0, null))).toBe(true));
});

describe("canView: alternate cuts", () => {
  it("treats other-edition timestamps as whole episode", () => expect(canView(mid, b(streamer, 2, 300))).toBe(false));
  it("treats edition-less timestamps as whole episode", () => expect(canView(mid, b(null, 2, 300))).toBe(false));
  it("shows earlier episodes regardless of edition", () => expect(canView(mid, b(streamer, 1, 9999))).toBe(true));
});

describe("canView: unknown boundaries are denied", () => {
  it("null show", () => expect(canView(mid, b(broadcast, 1, null, null))).toBe(false));
  it("null episode", () => expect(canView(mid, b(broadcast, null, 0))).toBe(false));
  it("negative episode", () => expect(canView(mid, b(broadcast, -1, 0))).toBe(false));
  it("progress for a different show", () => expect(canView(mid, b(broadcast, 1, null, "other"))).toBe(false));
});

describe("canView: not started / signed out", () => {
  it("shows show-level content", () => expect(canView(null, b(null, 0, null))).toBe(true));
  it("hides E1", () => expect(canView(null, b(broadcast, 1, 0))).toBe(false));
});

describe("canView: completed episode", () => {
  it("shows whole-episode content", () => expect(canView(done, b(broadcast, 2, null))).toBe(true));
  it("hides the next episode", () => expect(canView(done, b(broadcast, 3, null))).toBe(false));
});
