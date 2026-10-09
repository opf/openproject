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
import {
  CollaborationTokenService,
  PROVIDER_AUTH_ERROR_EVENT,
  ProviderAuthErrorKind,
} from 'core-stimulus/services/documents/collaboration-token.service';
import type { Doc } from 'yjs';
import * as Y from 'yjs';

export default class extends Controller {
  static values = {
    hocuspocusUrl: String,
    documentName: String,
    collaborationTokenUrl: String,
  };

  declare readonly hocuspocusUrlValue:string;
  declare readonly documentNameValue:string;
  declare readonly collaborationTokenUrlValue:string;

  private collaborationTokenService:CollaborationTokenService | null = null;
  private ownedProvider:HocuspocusProvider | null = null;
  private currentToken = '';
  // A token created by the scheduled renewal, handed over to the provider by its next getToken call.
  private createdToken:string | null = null;

  private getToken = async ():Promise<string> => {
    if (this.createdToken !== null) {
      const token = this.createdToken;
      this.createdToken = null;
      return token;
    }

    try {
      const data = await CollaborationTokenService.fetchToken(
        this.collaborationTokenUrlValue,
        this.currentToken || undefined,
      );
      this.currentToken = data.token;
      this.collaborationTokenService?.scheduleNextToken(data.expiresInSeconds);
      return data.token;
    } catch (error) {
      if (!this.currentToken) {
        document.dispatchEvent(new CustomEvent(PROVIDER_AUTH_ERROR_EVENT, {
          detail: {
            kind: 'token_request' as ProviderAuthErrorKind,
            message: error instanceof Error ? error.message : 'Failed to create collaboration token',
          },
        }));
      }
      throw error;
    }
  };

  connect():void {
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

    // Destroy any existing service to prevent duplicate timers if connect() is called multiple times
    this.collaborationTokenService?.destroy();
    this.collaborationTokenService = new CollaborationTokenService(
      provider,
      this.collaborationTokenUrlValue,
      () => this.currentToken,
      (newToken) => {
        this.currentToken = newToken;
        this.createdToken = newToken;
      },
    );
  }

  disconnect():void {
    this.collaborationTokenService?.destroy();
    this.collaborationTokenService = null;

    // Only destroy if we still own the active provider. During Turbo navigation,
    // a new controller may have already replaced it — see destroyIfOwner().
    if (this.ownedProvider) {
      LiveCollaborationManager.destroyIfOwner(this.ownedProvider);
      this.ownedProvider = null;
    }
  }
}
