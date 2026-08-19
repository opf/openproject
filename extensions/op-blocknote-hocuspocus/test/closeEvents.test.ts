import { describe, expect, test } from "vitest";
import { TokenExpired, TokenExpiryMissing, unauthorized } from "../src/closeEvents";

describe("closeEvents", () => {
  describe("TokenExpired", () => {
    test("has code 4401 and descriptive reason", () => {
      expect(TokenExpired).toEqual({ code: 4401, reason: "Token expired" });
    });
  });

  describe("TokenExpiryMissing", () => {
    test("has code 4500 and descriptive reason", () => {
      expect(TokenExpiryMissing).toEqual({ code: 4500, reason: "Token expiry not set" });
    });
  });

  describe("unauthorized factory", () => {
    test("creates CloseEvent with code 4401 and custom reason", () => {
      expect(unauthorized("Custom reason")).toEqual({ code: 4401, reason: "Custom reason" });
    });
  });
});
