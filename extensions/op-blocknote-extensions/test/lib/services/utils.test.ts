import { describe, it, expect } from "vitest";
import { makeInstanceId } from "../../../lib/services/utils";

describe("makeInstanceId", () => {
  it("returns a non-empty string", () => {
    expect(typeof makeInstanceId()).toBe("string");
    expect(makeInstanceId().length).toBeGreaterThan(0);
  });

  it("returns a unique ID on each call", () => {
    const ids = new Set(Array.from({ length: 100 }, () => makeInstanceId()));
    expect(ids.size).toBe(100);
  });
});