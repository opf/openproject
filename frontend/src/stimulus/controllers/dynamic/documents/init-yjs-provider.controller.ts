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

import { HocuspocusProvider } from '@hocuspocus/provider';
import { Controller } from '@hotwired/stimulus';
import { LiveCollaborationManager } from 'core-stimulus/helpers/live-collaboration-helpers';
import {
  PROVIDER_AUTH_ERROR_EVENT,
  ProviderAuthErrorKind,
  TokenRefreshService,
} from 'core-stimulus/services/documents/token-refresh.service';
import type { Doc } from 'yjs';
import * as Y from 'yjs';

export default class extends Controller {
  static values = {
    hocuspocusUrl: String,
    tokenPayload: String,
    documentName: String,
    tokenExpiresInSeconds: Number,
    refreshUrl: String,
  };

  declare readonly hocuspocusUrlValue:string;
  declare readonly tokenPayloadValue:string;
  declare readonly documentNameValue:string;
  declare readonly tokenExpiresInSecondsValue:number;
  declare readonly refreshUrlValue:string;

  private tokenRefreshService:TokenRefreshService | null = null;
  private ownedProvider:HocuspocusProvider | null = null;
  private currentToken = '';
  private canUseCachedToken = true;

  // On initial load, the DOM token is fresh. On reconnection (e.g., after server restart),
  // we must fetch a fresh token since the cached one may be expired.
  private getToken = async ():Promise<string> => {
    if (this.canUseCachedToken) {
      this.canUseCachedToken = false;
      return this.currentToken;
    }
    const data = await TokenRefreshService.fetchToken(this.refreshUrlValue);
    this.currentToken = data.encrypted_token;
    return this.currentToken;
  };

  connect():void {
    this.currentToken = this.tokenPayloadValue;

    // If a provider for this document is already live, don't build a duplicate
    // — adopt it. Stimulus can fire connect() a second time (HMR replay, Turbo
    // morph, parent re-attach) without firing disconnect(); building a fresh
    // Y.Doc + provider in that case would destroy the live one and wipe the
    // editor's Y.UndoManager mid-session.
    const existing = LiveCollaborationManager.getCurrentSessionFor(this.documentNameValue);
    if (existing) {
      this.ownedProvider = existing.provider;
      return;
    }

    const ydoc:Doc = new Y.Doc();
    const provider = new HocuspocusProvider({
      url: this.hocuspocusUrlValue,
      name: this.documentNameValue,
      token: this.getToken,
      document: ydoc,
      onAuthenticationFailed: () => {
        document.dispatchEvent(new CustomEvent(PROVIDER_AUTH_ERROR_EVENT, {
          detail: { kind: 'authentication' as ProviderAuthErrorKind, message: 'Authentication failed' },
        }));
      },
    });

    LiveCollaborationManager.initializeYjsProvider(provider, ydoc, this.documentNameValue);
    this.ownedProvider = provider;

    if (this.refreshUrlValue && this.tokenExpiresInSecondsValue) {
      // Destroy any existing service to prevent duplicate timers if connect() is called multiple times
      this.tokenRefreshService?.destroy();
      this.tokenRefreshService = new TokenRefreshService(
        provider,
        this.refreshUrlValue,
        (newToken) => {
          this.currentToken = newToken;
          this.canUseCachedToken = true;
        },
      );
      this.tokenRefreshService.scheduleRefresh(this.tokenExpiresInSecondsValue);
    }
  }

  disconnect():void {
    this.tokenRefreshService?.destroy();
    this.tokenRefreshService = null;

    // Only destroy if we still own the active provider. During Turbo navigation,
    // a new controller may have already replaced it — see destroyIfOwner().
    if (this.ownedProvider) {
      LiveCollaborationManager.destroyIfOwner(this.ownedProvider);
      this.ownedProvider = null;
    }
  }
}
