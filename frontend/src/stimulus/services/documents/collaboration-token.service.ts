//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import type { HocuspocusProvider } from '@hocuspocus/provider';

export interface CollaborationTokenResponse {
  token:string;
  documentName:string;
  expiresAt:string;
  expiresInSeconds:number;
}

export type CollaborationTokenErrorKind = 'session_expired' | 'forbidden' | 'http_error' | 'unknown';

export class CollaborationTokenError extends Error {
  constructor(
    public readonly kind:CollaborationTokenErrorKind,
    message:string,
    public readonly status?:number,
  ) {
    super(message);
    this.name = 'CollaborationTokenError';
  }

  get isRetryable():boolean {
    if (this.kind === 'session_expired' || this.kind === 'forbidden') return false;
    if (this.status !== undefined) return this.status >= 500 || this.status === 429;
    return this.kind === 'unknown';
  }
}

const RENEWAL_THRESHOLD = 0.8; // 80% of the token lifetime
const RETRY_DELAY_MS = 5000;
const MAX_RETRIES = 3;
const MIN_RENEWAL_DELAY_MS = 1000;

export type ProviderAuthErrorKind = 'token_request' | 'authentication';
export const PROVIDER_AUTH_ERROR_EVENT = 'op:provider-auth-error';

/**
 * Creates collaboration tokens for Hocuspocus collaborative editing sessions
 * through the APIv3 collaboration token endpoint, using session auth.
 *
 * At 80% of the token lifetime, a new token is created with the current token
 * sent along, which revokes the current token shortly after. The new token is
 * synced to Hocuspocus via the built-in onTokenSync hook.
 *
 * ```
 * Client                                    OpenProject                    Hocuspocus
 *   │  [80% of token TTL]                        │                              │
 *   │── POST /api/v3/documents/:id/              │                              │
 *   │        collaboration_token {token} ───────►│ create new token,            │
 *   │                                            │ revoke previous one          │
 *   │◄──────────────────────────────── {token} ──│                              │
 *   │── sendToken() ─────────────────────────────┼─────────────────────────────►│ onTokenSync updates context
 *   │  [schedule next token]                     │                              │
 *   │                                            │                              │
 *   │  [422] previous token rejected:            │                              │
 *   │── POST without previous token ────────────►│                              │
 *   │                                            │                              │
 *   │  [5xx/429] retry up to 3x                  │                              │
 *   │  [401] stop - session expired              │                              │
 *   │  [403/4xx] stop - non-retryable            │                              │
 * ```
 */
export class CollaborationTokenService {
  private timer:ReturnType<typeof setTimeout> | null = null;
  private provider:HocuspocusProvider;
  private tokenUrl:string;
  private getCurrentToken:() => string;
  private onTokenCreated:(token:string) => void;
  private destroyed = false;
  private retryCount = 0;

  constructor(
    provider:HocuspocusProvider,
    tokenUrl:string,
    getCurrentToken:() => string,
    onTokenCreated:(token:string) => void,
  ) {
    this.provider = provider;
    this.tokenUrl = tokenUrl;
    this.getCurrentToken = getCurrentToken;
    this.onTokenCreated = onTokenCreated;
  }

  scheduleNextToken(expiresInSeconds:number):void {
    this.retryCount = 0;
    const delayMs = Math.max(
      MIN_RENEWAL_DELAY_MS,
      Math.floor(expiresInSeconds * RENEWAL_THRESHOLD * 1000),
    );
    this.scheduleNextTokenAfter(delayMs);
  }

  static async fetchToken(tokenUrl:string, previousToken?:string):Promise<CollaborationTokenResponse> {
    const response = await CollaborationTokenService.requestToken(tokenUrl, previousToken);

    // The previous token may have been revoked already, e.g. by a concurrent request.
    if (response.status === 422 && previousToken) {
      return CollaborationTokenService.fetchToken(tokenUrl);
    }

    if (response.status === 401) {
      throw new CollaborationTokenError('session_expired', 'Session expired', response.status);
    }

    if (response.status === 403) {
      throw new CollaborationTokenError('forbidden', 'Forbidden', response.status);
    }

    if (!response.ok) {
      throw new CollaborationTokenError('http_error', `HTTP ${response.status}: ${response.statusText}`, response.status);
    }

    try {
      return await response.json() as CollaborationTokenResponse;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to parse token response JSON';
      throw new CollaborationTokenError('http_error', message, response.status);
    }
  }

  private static requestToken(tokenUrl:string, previousToken?:string):Promise<Response> {
    return fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      credentials: 'same-origin',
      body: JSON.stringify(previousToken ? { token: previousToken } : {}),
    });
  }

  async createNextToken():Promise<void> {
    if (this.destroyed) return;

    try {
      const data = await CollaborationTokenService.fetchToken(this.tokenUrl, this.getCurrentToken() || undefined);
      if (this.destroyed) return;

      this.onTokenCreated(data.token);
      void this.provider.sendToken();
      this.scheduleNextToken(data.expiresInSeconds);
    } catch (error) {
      const tokenError = error instanceof CollaborationTokenError
        ? error
        : new CollaborationTokenError('unknown', error instanceof Error ? error.message : 'Unknown error');

      if (!tokenError.isRetryable || this.retryCount >= MAX_RETRIES) {
        this.emitFailureEvent(tokenError);
        return;
      }

      this.retryCount += 1;
      this.scheduleRetry();
    }
  }

  destroy():void {
    this.destroyed = true;
    this.clearTimer();
  }

  private emitFailureEvent(error:CollaborationTokenError):void {
    document.dispatchEvent(new CustomEvent(PROVIDER_AUTH_ERROR_EVENT, {
      detail: { kind: 'token_request' as ProviderAuthErrorKind, message: error.message },
    }));
  }

  private scheduleRetry():void {
    this.scheduleNextTokenAfter(RETRY_DELAY_MS);
  }

  private scheduleNextTokenAfter(delayMs:number):void {
    this.clearTimer();

    if (this.destroyed) {
      return;
    }

    this.timer = setTimeout(() => {
      void this.createNextToken();
    }, delayMs);
  }

  private clearTimer():void {
    if (this.timer !== null) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }
}
