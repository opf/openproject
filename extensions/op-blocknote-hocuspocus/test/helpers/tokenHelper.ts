import { createCipheriv, createHash, randomBytes } from "node:crypto";
import { ALGORITHM, SECRET_ENV } from "../../src/services/decryptTokenService";

const SECRET = createHash("sha256").update(SECRET_ENV).digest();

interface TokenParams {
  resource_url: string;
  oauth_token: string;
  expires_at: string;
  readonly: boolean;
}

export function encryptToken(params: TokenParams): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGORITHM, SECRET, iv);

  const encrypted = Buffer.concat([
    cipher.update(JSON.stringify(params)),
    cipher.final()
  ]);

  const authTag = cipher.getAuthTag();

  return [
    encrypted.toString("base64"),
    iv.toString("base64"),
    authTag.toString("base64")
  ].join("--");
}

export function createTestToken(overrides: Partial<TokenParams> = {}): string {
  const futureDate = new Date(Date.now() + 5 * 60 * 1000); // 5 min from now

  return encryptToken({
    resource_url: "https://test.api/api/v3/documents/1",
    oauth_token: "some_token_value",
    expires_at: futureDate.toISOString(),
    readonly: false,
    ...overrides
  });
}

export function createExpiredToken(overrides: Partial<TokenParams> = {}): string {
  const pastDate = new Date(Date.now() - 60 * 1000); // 1 min ago

  return encryptToken({
    resource_url: "https://test.api/api/v3/documents/1",
    oauth_token: "some_token_value",
    expires_at: pastDate.toISOString(),
    readonly: false,
    ...overrides
  });
}
