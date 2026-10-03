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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import type { HocuspocusProvider } from '@hocuspocus/provider';
import { LiveCollaborationManager } from 'core-stimulus/helpers/live-collaboration-helpers';
import React from 'react';
import type { Root } from 'react-dom/client';
import { createRoot } from 'react-dom/client';
import type { WhiteboardUser } from '../react/whiteboard/whiteboard-awareness';

declare global {
  interface Window {
    EXCALIDRAW_ASSET_PATH?:string|string[];
  }
}

class WhiteboardElement extends HTMLElement {
  private reactRoot:Root|null = null;
  private renderCallback:((provider:HocuspocusProvider) => void) | null = null;

  connectedCallback() {
    window.EXCALIDRAW_ASSET_PATH = this.getAttribute('excalidraw-asset-path') ?? undefined;
    this.reactRoot = createRoot(this);

    this.renderCallback = (provider:HocuspocusProvider) => {
      void this.render(provider);
    };

    LiveCollaborationManager.onReady(this.renderCallback);
  }

  disconnectedCallback() {
    if (this.renderCallback) {
      LiveCollaborationManager.offReady(this.renderCallback);
      this.renderCallback = null;
    }

    this.reactRoot?.unmount();
    this.reactRoot = null;
  }

  private async render(provider:HocuspocusProvider) {
    const { default: OpWhiteboard } = await import('../react/whiteboard/OpWhiteboard');

    this.reactRoot?.render(
      React.createElement(OpWhiteboard, {
        provider,
        user: JSON.parse(this.getAttribute('active-user') ?? '{}') as WhiteboardUser,
        readOnly: this.getAttribute('read-only') === 'true',
        title: this.getAttribute('whiteboard-title') ?? '',
        updateUrl: this.getAttribute('update-url'),
        leaveUrl: this.getAttribute('leave-url') ?? '/',
        langCode: this.getAttribute('lang-code') ?? 'en',
      }),
    );
  }
}

if (!customElements.get('op-whiteboard')) {
  customElements.define('op-whiteboard', WhiteboardElement);
}
