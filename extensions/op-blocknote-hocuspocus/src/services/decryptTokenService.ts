import { createDecipheriv, createHash } from "node:crypto";

export const ALGORITHM = "aes-256-gcm";

if (!process.env.SECRET) {
  throw new Error("SECRET environment variable is not set.");
}
export const SECRET_ENV = process.env.SECRET;
const SECRET = createHash("sha256").update(SECRET_ENV).digest();

type PackedParams = {
  resource_url: string;
  oauth_token: string;
  expires_at: string;
  readonly: boolean;
};

/**
 * Decrypts a given token using AES-256-GCM algorithm.
 */
export function decryptToken(encrypted:string):PackedParams {
  const [token, iv, authTag] = encrypted.split('--').map((part:string) => Buffer.from(part, 'base64'));

  const decipher = createDecipheriv(ALGORITHM, SECRET, iv);
  decipher.setAuthTag(authTag);

  const decrypted = Buffer.concat([
    decipher.update(token),
    decipher.final()
  ]);

  return JSON.parse(decrypted.toString());
}
