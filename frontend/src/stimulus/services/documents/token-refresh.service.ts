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
import { getMetaContent } from 'core-app/core/setup/globals/global-helpers';

export interface TokenResponse {
  encrypted_token:string;
  expires_in_seconds:number;
}

export type RefreshErrorKind = 'access_denied' | 'unavailable' | 'rejected';

export class RefreshError extends Error {
  constructor(
    public readonly kind:RefreshErrorKind,
    message:string,
    public readonly status?:number,
  ) {
    super(message);
    this.name = 'RefreshError';
  }

  get isAccessDenied():boolean {
    return this.kind === 'access_denied';
  }

  get isRetryable():boolean {
    return this.kind === 'unavailable';
  }
}

const REFRESH_THRESHOLD = 0.8; // 80% of the token lifetime
const RETRY_DELAY_MS = 5000;
const MAX_RETRIES = 3;
const MIN_REFRESH_DELAY_MS = 1000;
const ACQUIRE_INITIAL_DELAY_MS = 1000;
const ACQUIRE_MAX_DELAY_MS = 30000;

const destroyedError = ():RefreshError => new RefreshError('unavailable', 'Token service destroyed');

export type ProviderAuthErrorKind = 'token_refresh' | 'authentication' | 'access_denied';
export const PROVIDER_AUTH_ERROR_EVENT = 'op:provider-auth-error';

/**
 * Manages OAuth token refresh for Hocuspocus collaborative editing sessions.
 *
 * Proactively refreshes tokens at 80% of lifetime using session auth,
 * then syncs new token to Hocuspocus server via built-in onTokenSync hook.
 *
 * ```
 * Client                              OpenProject                         Hocuspocus
 *   │  [80% of token TTL]                  │                                   │
 *   │── POST /refresh_token ──────────────►│                                   │
 *   │                                      │                                   │
 *   │  [success]                           │                                   │
 *   │◄─────────────── {encrypted_token} ───│                                   │
 *   │── sendToken() ───────────────────────┼──────────────────────────────────►│ onTokenSync updates context
 *   │  [schedule next refresh]             │                                   │
 *   │                                      │                                   │
 *   │  [5xx error] retry up to 3x          │                                   │
 *   │── POST /refresh_token ──────────────►│                                   │
 *   │                                      │                                   │
 *   │  [401/403/404] stop - access denied  │                                   │
 *   │  [4xx] stop - non-retryable          │                                   │
 * ```
 */
export class TokenRefreshService {
  private refreshTimer:ReturnType<typeof setTimeout> | null = null;
  private destroyed = false;
  private retryCount = 0;
  private pendingAcquire:Promise<TokenResponse> | null = null;
  private cancelBackoff:(() => void) | null = null;

  constructor(
    private readonly provider:HocuspocusProvider,
    private readonly refreshUrl:string,
    private readonly onTokenRefreshed:(token:string) => void,
    private readonly onFailure:(error:RefreshError) => void,
  ) {}

  scheduleRefresh(expiresInSeconds:number):void {
    this.retryCount = 0;
    const delayMs = Math.max(
      MIN_REFRESH_DELAY_MS,
      Math.floor(expiresInSeconds * REFRESH_THRESHOLD * 1000),
    );
    this.scheduleRefreshAfter(delayMs);
  }

  /**
   * Fetches a token for a reconnecting provider. Transient failures are retried until the web
   * server responds, so the provider only ever sees a rejection for a real problem.
   */
  acquireToken():Promise<TokenResponse> {
    if (this.pendingAcquire) return this.pendingAcquire;

    this.pendingAcquire = this.fetchWithBackoff().finally(() => {
      this.pendingAcquire = null;
    });

    return this.pendingAcquire;
  }

  static async fetchToken(refreshUrl:string):Promise<TokenResponse> {
    let response:Response;
    try {
      response = await fetch(refreshUrl, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': getMetaContent('csrf-token'),
        },
        credentials: 'same-origin',
      });
    } catch (error) {
      throw new RefreshError('unavailable', error instanceof Error ? error.message : 'Network error');
    }

    if (response.status === 401 || response.status === 403 || response.status === 404) {
      throw new RefreshError('access_denied', `HTTP ${response.status}`, response.status);
    }

    if (!response.ok) {
      const retryable = response.status >= 500 || response.status === 429 || response.status === 408;
      throw new RefreshError(
        retryable ? 'unavailable' : 'rejected',
        `HTTP ${response.status}: ${response.statusText}`,
        response.status,
      );
    }

    let payload:Partial<TokenResponse>;
    try {
      payload = await response.json() as Partial<TokenResponse>;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to parse token response JSON';
      throw new RefreshError('unavailable', message, response.status);
    }

    const { encrypted_token: token, expires_in_seconds: expiresIn } = payload ?? {};
    if (typeof token !== 'string' || token === '' || typeof expiresIn !== 'number' || !Number.isFinite(expiresIn) || expiresIn <= 0) {
      throw new RefreshError('unavailable', 'Malformed token response', response.status);
    }

    return { encrypted_token: token, expires_in_seconds: expiresIn };
  }

  async performRefresh():Promise<void> {
    if (this.destroyed) return;

    try {
      const data = await TokenRefreshService.fetchToken(this.refreshUrl);
      if (this.destroyed) return;

      this.onTokenRefreshed(data.encrypted_token);
      void this.provider.sendToken();
      this.scheduleRefresh(data.expires_in_seconds);
    } catch (error) {
      if (this.destroyed) return;

      const refreshError = error instanceof RefreshError
        ? error
        : new RefreshError('unavailable', error instanceof Error ? error.message : 'Unknown error');

      if (!refreshError.isRetryable || this.retryCount >= MAX_RETRIES) {
        this.onFailure(refreshError);
        return;
      }

      this.retryCount += 1;
      this.scheduleRetry();
    }
  }

  destroy():void {
    this.destroyed = true;
    this.clearTimer();
    this.cancelBackoff?.();
  }

  private async fetchWithBackoff():Promise<TokenResponse> {
    let delayMs = ACQUIRE_INITIAL_DELAY_MS;

    while (true) {
      try {
        if (this.destroyed) throw destroyedError();

        const data = await TokenRefreshService.fetchToken(this.refreshUrl);
        if (this.destroyed) throw destroyedError();

        this.scheduleRefresh(data.expires_in_seconds);
        return data;
      } catch (error) {
        if (this.destroyed) throw destroyedError();
        if (!(error instanceof RefreshError) || !error.isRetryable) throw error;

        await this.waitForBackoff(delayMs);
        delayMs = Math.min(delayMs * 2, ACQUIRE_MAX_DELAY_MS);
      }
    }
  }

  private waitForBackoff(delayMs:number):Promise<void> {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.cancelBackoff = null;
        resolve();
      }, delayMs);

      this.cancelBackoff = () => {
        clearTimeout(timer);
        this.cancelBackoff = null;
        reject(destroyedError());
      };
    });
  }

  private scheduleRetry():void {
    this.scheduleRefreshAfter(RETRY_DELAY_MS);
  }

  private scheduleRefreshAfter(delayMs:number):void {
    this.clearTimer();

    if (this.destroyed) {
      return;
    }

    this.refreshTimer = setTimeout(() => {
      void this.performRefresh();
    }, delayMs);
  }

  private clearTimer():void {
    if (this.refreshTimer !== null) {
      clearTimeout(this.refreshTimer);
      this.refreshTimer = null;
    }
  }
}
