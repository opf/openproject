import { decryptToken } from "./decryptTokenService";
import { fetchResource } from "./resourceService";
import type { ApiResponseDocument } from "../types";

export interface TokenValidationResult {
  decryptedToken: string;
  readonly: boolean;
  tokenExpiresAt: string;
}

/**
 * Decrypt and validate packed auth params against the OpenProject API.
 * Validates origin and resource URL match, then verifies access with the API.
 * Returns the decrypted oauth_token and readonly status, or throws if validation fails.
 */
export async function decryptAndValidateToken(
  encryptedToken: string,
  resourceUrl: string,
  requestOrigin?: string
): Promise<TokenValidationResult> {
  const {
    resource_url: tokenResourceUrl,
    oauth_token,
    expires_at,
  } = decryptToken(encryptedToken);

  if (requestOrigin && !tokenResourceUrl?.startsWith(requestOrigin)) {
    throw new Error(`Unauthorized: Token origin does not match request origin. Expected ${tokenResourceUrl} to start with ${requestOrigin}.`);
  }

  if (tokenResourceUrl !== resourceUrl) {
    throw new Error(`Unauthorized: Token resource URL does not match document. Expected ${tokenResourceUrl}, got ${resourceUrl}.`);
  }

  const response = await fetchResource(resourceUrl, oauth_token);

  if (!response.ok) {
    const detail = response.statusText ? `: ${response.statusText}` : ".";
    throw new Error(`Unauthorized: Invalid token or document access denied${detail}`);
  }

  const jsonData = await response.json() as ApiResponseDocument;
  return {
    decryptedToken: oauth_token,
    readonly: !jsonData._links?.update,
    tokenExpiresAt: expires_at,
  };
}
