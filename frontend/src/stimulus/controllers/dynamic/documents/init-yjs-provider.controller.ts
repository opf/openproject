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

import { HocuspocusProvider } from '@hocuspocus/provider';
import { Controller } from '@hotwired/stimulus';
import { LiveCollaborationManager } from 'core-stimulus/helpers/live-collaboration-helpers';
import { DocumentCache } from 'core-stimulus/services/documents/document-cache.service';
import {
  PROVIDER_AUTH_ERROR_EVENT,
  ProviderAuthErrorKind,
  RefreshError,
  TokenRefreshService,
} from 'core-stimulus/services/documents/token-refresh.service';
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
  private cache:DocumentCache | null = null;
  private currentToken = '';
  private canUseCachedToken = true;
  private accessDenied = false;
  private generation = 0;

  connect():void {
    if (this.hasLiveSession()) {
      this.adoptLiveSession();
      return;
    }

    this.generation += 1;
    void this.setUp(this.generation);
  }

  disconnect():void {
    this.generation += 1;

    this.tokenRefreshService?.destroy();
    this.tokenRefreshService = null;

    this.cache?.close();
    this.cache = null;

    // Only destroy if we still own the active provider. During Turbo navigation,
    // a new controller may have already replaced it — see destroyIfOwner().
    if (this.ownedProvider) {
      LiveCollaborationManager.destroyIfOwner(this.ownedProvider);
      this.ownedProvider = null;
    }
  }

  private hasLiveSession():boolean {
    return LiveCollaborationManager.getCurrentSessionFor(this.documentNameValue) !== null;
  }

  /**
   * If a provider for this document is already live, don't build a duplicate - adopt it.
   * Stimulus can fire connect() a second time (HMR replay, Turbo morph, parent re-attach)
   * without firing disconnect(); building a fresh Y.Doc + provider in that case would destroy
   * the live one and wipe the editor's Y.UndoManager mid-session.
   */
  private adoptLiveSession():void {
    const existing = LiveCollaborationManager.getCurrentSessionFor(this.documentNameValue);
    this.ownedProvider = existing?.provider ?? null;
  }

  /**
   * The cache is opened before the provider exists so that cached content is already in the
   * document when the editor first renders.
   */
  private async setUp(generation:number):Promise<void> {
    const doc = new Y.Doc();
    let cache:DocumentCache | null = null;

    try {
      cache = await DocumentCache.open(this.documentNameValue, doc);

      if (generation !== this.generation) {
        this.release(doc, cache);
        return;
      }

      if (this.hasLiveSession()) {
        this.adoptLiveSession();
        this.release(doc, cache);
        return;
      }

      this.startSession(doc, cache, generation);
    } catch (error) {
      this.releaseUnlessHandedOver(doc, cache);
      this.reportSetUpFailure(error);
    }
  }

  private startSession(doc:Y.Doc, cache:DocumentCache | null, generation:number):void {
    const provider = this.createProvider(doc, generation);
    const refreshService = this.createTokenRefreshService(provider);

    this.cache = cache;
    this.accessDenied = false;
    this.currentToken = this.tokenPayloadValue;
    this.canUseCachedToken = true;
    this.tokenRefreshService = refreshService;
    this.ownedProvider = provider;

    LiveCollaborationManager.initializeYjsProvider(provider, doc, this.documentNameValue);

    if (this.tokenExpiresInSecondsValue) {
      refreshService.scheduleRefresh(this.tokenExpiresInSecondsValue);
    }
  }

  private createProvider(doc:Y.Doc, generation:number):HocuspocusProvider {
    return new HocuspocusProvider({
      url: this.hocuspocusUrlValue,
      name: this.documentNameValue,
      token: () => this.getToken(generation),
      document: doc,
      onAuthenticationFailed: ({ reason }) => {
        if (this.accessDenied || generation !== this.generation) return;

        this.dispatchAuthError('authentication', reason);
      },
    });
  }

  /**
   * On initial load, the DOM token is fresh. On reconnection (e.g., after server restart),
   * we must fetch a fresh token since the cached one may be expired.
   */
  private async getToken(generation:number):Promise<string> {
    const refreshService = this.tokenRefreshService;
    if (generation !== this.generation || !refreshService) {
      throw new RefreshError('unavailable', 'Collaboration session ended');
    }

    if (this.accessDenied) {
      throw new RefreshError('access_denied', 'Access to the document was revoked');
    }

    if (this.canUseCachedToken) {
      this.canUseCachedToken = false;
      return this.currentToken;
    }

    try {
      const data = await refreshService.acquireToken();
      this.currentToken = data.encrypted_token;
      return this.currentToken;
    } catch (error) {
      if (error instanceof RefreshError && error.isAccessDenied && generation === this.generation) {
        this.handleAccessDenied();
      }
      throw error;
    }
  }

  private createTokenRefreshService(provider:HocuspocusProvider):TokenRefreshService {
    return new TokenRefreshService(
      provider,
      this.refreshUrlValue,
      (newToken) => {
        this.currentToken = newToken;
        this.canUseCachedToken = true;
      },
      (error) => this.handleRefreshFailure(error),
    );
  }

  private handleRefreshFailure(error:RefreshError):void {
    if (error.isAccessDenied) {
      this.handleAccessDenied();
      return;
    }

    this.dispatchAuthError('token_refresh', error.message);
  }

  /**
   * The web server refused the token: the session ended or access was revoked. The offline copy
   * must not outlive that, and unsynced edits must not be pushed later. The provider and
   * document stay alive because the editor still references them.
   */
  private handleAccessDenied():void {
    if (this.accessDenied) return;
    this.accessDenied = true;

    this.tokenRefreshService?.destroy();
    this.stopSocket();
    void this.evictCache();

    this.dispatchAuthError('access_denied', 'Access to the document was revoked');
  }

  private stopSocket():void {
    this.ownedProvider?.configuration.websocketProvider.disconnect();
  }

  private evictCache():Promise<void> {
    const { cache } = this;
    this.cache = null;

    if (cache) {
      return cache.evict();
    }

    return DocumentCache.evict(this.documentNameValue);
  }

  private dispatchAuthError(kind:ProviderAuthErrorKind, message:string):void {
    document.dispatchEvent(new CustomEvent(PROVIDER_AUTH_ERROR_EVENT, { detail: { kind, message } }));
  }

  private releaseUnlessHandedOver(doc:Y.Doc, cache:DocumentCache | null):void {
    const handedOver = LiveCollaborationManager.getCurrentSessionFor(this.documentNameValue)?.doc === doc;
    if (handedOver) return;

    this.release(doc, cache);
  }

  private release(doc:Y.Doc, cache:DocumentCache | null):void {
    cache?.close();
    doc.destroy();
  }

  private reportSetUpFailure(error:unknown):void {
    const cause = error instanceof Error ? error : new Error(String(error));
    this.application.handleError(cause, 'Error setting up the collaboration session', { identifier: this.identifier });
  }
}
