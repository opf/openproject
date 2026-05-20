import { describe, it, expect } from "vitest";
import { makeInstanceId, formatWorkPackageId } from "../../../lib/utils/id.ts";

describe("formatWorkPackageId", () => {
  it("prepends # to a purely numeric string", () => {
    expect(formatWorkPackageId("123")).toBe("#123");
    expect(formatWorkPackageId("37")).toBe("#37");
    expect(formatWorkPackageId("1")).toBe("#1");
  });

  it("returns alphanumeric displayId as-is without # prefix", () => {
    expect(formatWorkPackageId("DWPS-1")).toBe("DWPS-1");
    expect(formatWorkPackageId("ABC123")).toBe("ABC123");
    expect(formatWorkPackageId("PROJ-42")).toBe("PROJ-42");
  });
});

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