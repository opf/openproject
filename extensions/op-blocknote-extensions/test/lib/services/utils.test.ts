import { describe, it, expect } from "vitest";
import { makeInstanceId } from "../../../lib/services/utils";

describe("makeInstanceId", () => {
  it("returns a non-empty string", () => {
    expect(typeof makeInstanceId()).toBe("string");
    expect(makeInstanceId().length).toBeGreaterThan(0);
  });

  it("returns a unique ID on each call", () => {
    const ids = Array.from({ length: 100 }, () => makeInstanceId());

    for (let i = 0; i < ids.length - 1; i++) {
      expect(ids[i]).not.toBe(ids[i + 1]);
    }

    expect(new Set(ids).size).toBe(ids.length);
  });
});