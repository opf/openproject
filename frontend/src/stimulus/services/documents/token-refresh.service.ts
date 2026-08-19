/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import type { HocuspocusProvider } from '@hocuspocus/provider';
import { getMetaContent } from 'core-app/core/setup/globals/global-helpers';

export interface TokenResponse {
  encrypted_token:string;
  expires_at:string;
  expires_in_seconds:number;
}

export type RefreshErrorKind = 'session_expired' | 'http_error' | 'unknown';

export class RefreshError extends Error {
  constructor(
    public readonly kind:RefreshErrorKind,
    message:string,
    public readonly status?:number,
  ) {
    super(message);
    this.name = 'RefreshError';
  }

  get isRetryable():boolean {
    if (this.kind === 'session_expired') return false;
    if (this.status !== undefined) return this.status >= 500 || this.status === 429;
    return this.kind === 'unknown';
  }
}

const REFRESH_THRESHOLD = 0.8; // 80% of the token lifetime
const RETRY_DELAY_MS = 5000;
const MAX_RETRIES = 3;
const MIN_REFRESH_DELAY_MS = 1000;

export type ProviderAuthErrorKind = 'token_refresh' | 'authentication';
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
 *   │  [401/403] stop - session expired    │                                   │
 *   │  [4xx] stop - non-retryable          │                                   │
 * ```
 */
export class TokenRefreshService {
  private refreshTimer:ReturnType<typeof setTimeout> | null = null;
  private provider:HocuspocusProvider;
  private refreshUrl:string;
  private onTokenRefreshed:(token:string) => void;
  private destroyed = false;
  private retryCount = 0;

  constructor(
    provider:HocuspocusProvider,
    refreshUrl:string,
    onTokenRefreshed:(token:string) => void,
  ) {
    this.provider = provider;
    this.refreshUrl = refreshUrl;
    this.onTokenRefreshed = onTokenRefreshed;
  }

  scheduleRefresh(expiresInSeconds:number):void {
    this.retryCount = 0;
    const delayMs = Math.max(
      MIN_REFRESH_DELAY_MS,
      Math.floor(expiresInSeconds * REFRESH_THRESHOLD * 1000),
    );
    this.scheduleRefreshAfter(delayMs);
  }

  static async fetchToken(refreshUrl:string):Promise<TokenResponse> {
    const response = await fetch(refreshUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': getMetaContent('csrf-token'),
      },
      credentials: 'same-origin',
    });

    if (response.status === 401 || response.status === 403) {
      throw new RefreshError('session_expired', 'Session expired', response.status);
    }

    if (!response.ok) {
      throw new RefreshError('http_error', `HTTP ${response.status}: ${response.statusText}`, response.status);
    }

    try {
      return await response.json() as TokenResponse;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to parse token response JSON';
      throw new RefreshError('http_error', message, response.status);
    }
  }

  async performRefresh():Promise<void> {
    if (this.destroyed) return;

    try {
      const data = await TokenRefreshService.fetchToken(this.refreshUrl);

      this.onTokenRefreshed(data.encrypted_token);
      void this.provider.sendToken();
      this.scheduleRefresh(data.expires_in_seconds);
    } catch (error) {
      const refreshError = error instanceof RefreshError
        ? error
        : new RefreshError('unknown', error instanceof Error ? error.message : 'Unknown error');

      if (!refreshError.isRetryable || this.retryCount >= MAX_RETRIES) {
        this.emitFailureEvent(refreshError);
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

  private emitFailureEvent(error:RefreshError):void {
    document.dispatchEvent(new CustomEvent(PROVIDER_AUTH_ERROR_EVENT, {
      detail: { kind: 'token_refresh' as ProviderAuthErrorKind, message: error.message },
    }));
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
