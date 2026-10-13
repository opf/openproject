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
import { ChannelNameWithParams, Consumer, createConsumer, Subscription } from '@rails/actioncable';
import { snakeCase } from 'lodash-es';

export const WEBSOCKET_TIMEOUT_MS = 5_000;
export const TRANSPORT_STORAGE_KEY = 'op-cable-transport';

// Takes the place of turbo-rails' <turbo-cable-stream-source> (rendered by `turbo_stream_from`),
// following its implementation, and falls back to AnyCable's SSE endpoint when no WebSocket can be
// opened, e.g. behind proxies that strip the Upgrade header. Both transports subscribe to the same
// channel, so the subscription is authorized by OpenProject over RPC either way.
export class CableStreamSourceElement extends HTMLElement {
  static observedAttributes = ['channel', 'signed-stream-name'];

  private static consumer?:Consumer;
  private static webSocketSources = new Set<CableStreamSourceElement>();

  private subscription?:Subscription;
  private eventSource?:EventSource;
  private fallbackTimer?:number;

  connectedCallback():void {
    connectStreamSource(this);

    if (this.sseUsed()) {
      this.connectEventSource();
    } else {
      this.connectWebSocket();
    }
  }

  disconnectedCallback():void {
    this.disconnectWebSocket();
    this.disconnectEventSource();
    disconnectStreamSource(this);
  }

  attributeChangedCallback():void {
    if (this.subscription || this.eventSource) {
      this.disconnectedCallback();
      this.connectedCallback();
    }
  }

  dispatchMessageEvent(data:unknown):boolean {
    return this.dispatchEvent(new MessageEvent('message', { data }));
  }

  subscriptionConnected():void {
    window.clearTimeout(this.fallbackTimer);
    this.setAttribute('connected', '');
  }

  subscriptionDisconnected({ willAttemptReconnect }:{ willAttemptReconnect:boolean|undefined }):void {
    this.removeAttribute('connected');

    // The server refused the connection (e.g. not logged in); SSE would be refused too.
    if (!willAttemptReconnect) {
      window.clearTimeout(this.fallbackTimer);
    }
  }

  // Like turbo-rails, data attributes are passed on as snake_case channel parameters.
  get channel():ChannelNameWithParams {
    const params = Object.fromEntries(Object.entries(this.dataset).map(([key, value]) => [snakeCase(key), value]));

    return {
      channel: this.getAttribute('channel') ?? 'Turbo::StreamsChannel',
      signed_stream_name: this.getAttribute('signed-stream-name'),
      ...params,
    };
  }

  private connectWebSocket():void {
    CableStreamSourceElement.webSocketSources.add(this);
    this.fallbackTimer = window.setTimeout(() => this.fallBackToEventSource(), WEBSOCKET_TIMEOUT_MS);

    this.subscription = this.getConsumer().subscriptions.create(this.channel, {
      received: this.dispatchMessageEvent.bind(this),
      connected: this.subscriptionConnected.bind(this),
      disconnected: this.subscriptionDisconnected.bind(this),
      rejected: () => window.clearTimeout(this.fallbackTimer),
    });
  }

  private disconnectWebSocket():void {
    window.clearTimeout(this.fallbackTimer);
    this.subscription?.unsubscribe();
    this.subscription = undefined;
    this.removeAttribute('connected');
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
    const identifier = encodeURIComponent(JSON.stringify(this.channel));
    this.eventSource = new EventSource(`${window.appBasePath ?? ''}/events?identifier=${identifier}`);
    this.eventSource.addEventListener('message', this.receiveEventSourceMessage);
    this.eventSource.addEventListener('open', () => this.setAttribute('connected', ''));
    this.eventSource.addEventListener('error', () => this.removeAttribute('connected'));
  }

  private disconnectEventSource():void {
    this.eventSource?.close();
    this.eventSource = undefined;
    this.removeAttribute('connected');
  }

  // AnyCable sends each broadcast JSON-encoded over SSE, while Turbo expects the stream HTML itself.
  private receiveEventSourceMessage = (event:MessageEvent<string>) => {
    this.dispatchMessageEvent(JSON.parse(event.data) as unknown);
  };

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
