import { describe, expect, test } from "vitest";
import { decryptToken } from "../../src/services/decryptTokenService";
import { createTestToken } from "../helpers/tokenHelper";

describe("decryptToken", () => {
  test("should decrypt a valid encrypted token with expires_at", () => {
    const encrypted = createTestToken({ expires_at: "2030-01-01T00:00:00.000Z" });
    const decrypted = decryptToken(encrypted);

    expect(decrypted.resource_url).toBe("https://test.api/api/v3/documents/1");
    expect(decrypted.oauth_token).toBe("some_token_value");
    expect(decrypted.readonly).toBe(false);
    expect(decrypted.expires_at).toBe("2030-01-01T00:00:00.000Z");
  });
});
