import type { CloseEvent } from "@hocuspocus/common";

/**
 * WebSocket close codes 4000-4999 are reserved for application use.
 * We mirror HTTP status codes where applicable.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/close
 * @see https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent/code
 */

/**
 * Token has expired. Client should refresh and reconnect.
 * Code 4401 mirrors HTTP 401 Unauthorized.
 */
export const TokenExpired: CloseEvent = {
  code: 4401,
  reason: "Token expired",
};

/**
 * Token expiry timestamp missing from connection context.
 * Indicates a server configuration or authentication flow issue.
 * Code 4500 mirrors HTTP 500 Internal Server Error.
 */
export const TokenExpiryMissing: CloseEvent = {
  code: 4500,
  reason: "Token expiry not set",
};

/**
 * Factory for creating Unauthorized close events with custom reasons.
 * Use for token sync failures, validation errors, etc.
 */
export function unauthorized(reason: string): CloseEvent {
  return { code: 4401, reason };
}
