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

import { connectStreamSource, disconnectStreamSource } from '@hotwired/turbo';
import { Consumer, createConsumer, Subscription } from '@rails/actioncable';

export const WEBSOCKET_TIMEOUT_MS = 5_000;
export const TRANSPORT_STORAGE_KEY = 'op-cable-transport';

// Replaces turbo-rails' <turbo-cable-stream-source> (rendered by `turbo_stream_from`) to fall
// back to AnyCable's SSE endpoint when no WebSocket can be opened, e.g. behind proxies that
// strip the Upgrade header. The fallback is Turbo's own <turbo-stream-source>, which cannot
// replace the WebSocket path because AnyCable's WebSocket speaks the Action Cable protocol.
export class CableStreamSourceElement extends HTMLElement {
  private static consumer?:Consumer;
  private static webSocketSources = new Set<CableStreamSourceElement>();

  private subscription?:Subscription;
  private fallbackTimer?:number;

  connectedCallback():void {
    if (this.sseUsed()) {
      this.connectEventSource();
    } else {
      this.connectWebSocket();
    }
  }

  disconnectedCallback():void {
    this.disconnectWebSocket();
  }

  private get signedStreamName():string {
    return this.getAttribute('signed-stream-name') ?? '';
  }

  private connectWebSocket():void {
    connectStreamSource(this);
    CableStreamSourceElement.webSocketSources.add(this);
    this.fallbackTimer = window.setTimeout(() => this.fallBackToEventSource(), WEBSOCKET_TIMEOUT_MS);

    this.subscription = this.getConsumer().subscriptions.create(
      {
        channel: this.getAttribute('channel') ?? 'Turbo::StreamsChannel',
        signed_stream_name: this.signedStreamName,
      },
      {
        received: (data:string) => this.dispatchEvent(new MessageEvent('message', { data })),
        connected: () => {
          window.clearTimeout(this.fallbackTimer);
          this.setAttribute('connected', '');
        },
        disconnected: ({ willAttemptReconnect }:{ willAttemptReconnect:boolean|undefined }) => {
          this.removeAttribute('connected');
          // The server refused the connection (e.g. not logged in); SSE would be refused too.
          if (!willAttemptReconnect) {
            window.clearTimeout(this.fallbackTimer);
          }
        },
        rejected: () => window.clearTimeout(this.fallbackTimer),
      },
    );
  }

  private disconnectWebSocket():void {
    window.clearTimeout(this.fallbackTimer);
    this.subscription?.unsubscribe();
    this.subscription = undefined;
    this.removeAttribute('connected');
    disconnectStreamSource(this);
    CableStreamSourceElement.webSocketSources.delete(this);
  }

  private fallBackToEventSource():void {
    this.useSse();
    this.disconnectWebSocket();
    if (CableStreamSourceElement.webSocketSources.size === 0) {
      CableStreamSourceElement.consumer?.disconnect();
    }
    this.connectEventSource();
  }

  private connectEventSource():void {
    const name = encodeURIComponent(this.signedStreamName);
    const source = document.createElement('turbo-stream-source');
    source.setAttribute('src', `${window.appBasePath ?? ''}/events?turbo_signed_stream_name=${name}`);
    this.replaceChildren(source);
  }

  private getConsumer():Consumer {
    CableStreamSourceElement.consumer ??= createConsumer();
    return CableStreamSourceElement.consumer;
  }

  private sseUsed():boolean {
    try {
      return sessionStorage.getItem(TRANSPORT_STORAGE_KEY) === 'sse';
    } catch {
      return false;
    }
  }

  private useSse():void {
    // Remember to use SSE for the current session only.
    // If a new tab is opened, websockets would be retried.
    try {
      sessionStorage.setItem(TRANSPORT_STORAGE_KEY, 'sse');
    } catch {
      // Storage unavailable: the next page falls back again after the timeout.
    }
  }
}

export function registerCableStreamSourceElement():void {
  if (customElements.get('turbo-cable-stream-source') === undefined) {
    customElements.define('turbo-cable-stream-source', CableStreamSourceElement);
  }
}
