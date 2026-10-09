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

import { BaseMixin } from '@rails/actioncable';
import {
  registerCableStreamSourceElement,
  TRANSPORT_STORAGE_KEY,
  WEBSOCKET_TIMEOUT_MS,
} from './cable-stream-source-element';

const { consumer, subscription } = vi.hoisted(() => {
  const unsubscribable = { unsubscribe: vi.fn() };
  return {
    subscription: unsubscribable,
    consumer: {
      subscriptions: { create: vi.fn((_params:object, _mixin:BaseMixin) => unsubscribable) },
      disconnect: vi.fn(),
    },
  };
});

vi.mock('@rails/actioncable', () => ({ createConsumer: () => consumer }));

class FakeEventSource extends EventTarget {
  static instances:FakeEventSource[] = [];

  close = vi.fn();

  constructor(public url:string) {
    super();
    FakeEventSource.instances.push(this);
  }
}

describe('turbo-cable-stream-source', () => {
  let element:HTMLElement;

  const mixin = ():BaseMixin => consumer.subscriptions.create.mock.calls[0][1];

  const attach = ():void => {
    element = document.createElement('turbo-cable-stream-source');
    element.setAttribute('channel', 'Turbo::StreamsChannel');
    element.setAttribute('signed-stream-name', 'signed==--abc');
    document.body.appendChild(element);
  };

  beforeAll(() => registerCableStreamSourceElement());

  beforeEach(() => {
    vi.useFakeTimers();
    vi.stubGlobal('EventSource', FakeEventSource);
    FakeEventSource.instances = [];
    sessionStorage.clear();
    consumer.subscriptions.create.mockClear();
    consumer.disconnect.mockClear();
    subscription.unsubscribe.mockClear();
  });

  afterEach(() => {
    element.remove();
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('subscribes over the WebSocket with the signed stream name', () => {
    attach();
    mixin().connected?.({ reconnected: false });

    expect(consumer.subscriptions.create).toHaveBeenCalledWith(
      { channel: 'Turbo::StreamsChannel', signed_stream_name: 'signed==--abc' },
      expect.any(Object),
    );
    expect(element.hasAttribute('connected')).toBe(true);
  });

  it('re-dispatches received broadcasts as message events', () => {
    attach();
    const listener = vi.fn();
    element.addEventListener('message', listener);

    mixin().received?.('broadcast');

    expect((listener.mock.calls[0][0] as MessageEvent).data).toBe('broadcast');
  });

  it('stays on the WebSocket once connected', () => {
    attach();
    mixin().connected?.({ reconnected: false });

    vi.advanceTimersByTime(WEBSOCKET_TIMEOUT_MS);

    expect(FakeEventSource.instances).toHaveLength(0);
  });

  it('falls back to SSE when the WebSocket does not connect in time', () => {
    attach();

    vi.advanceTimersByTime(WEBSOCKET_TIMEOUT_MS);

    expect(subscription.unsubscribe).toHaveBeenCalled();
    expect(consumer.disconnect).toHaveBeenCalled();
    expect(element.querySelector('turbo-stream-source')?.getAttribute('src'))
      .toBe('/events?turbo_signed_stream_name=signed%3D%3D--abc');
    expect(FakeEventSource.instances[0].url).toBe('/events?turbo_signed_stream_name=signed%3D%3D--abc');
    expect(sessionStorage.getItem(TRANSPORT_STORAGE_KEY)).toBe('sse');
  });

  it('uses SSE right away once a fallback happened in this session', () => {
    sessionStorage.setItem(TRANSPORT_STORAGE_KEY, 'sse');

    attach();

    expect(consumer.subscriptions.create).not.toHaveBeenCalled();
    expect(FakeEventSource.instances).toHaveLength(1);
  });

  it('does not fall back when the server refuses the connection', () => {
    attach();
    mixin().disconnected?.({ willAttemptReconnect: false });

    vi.advanceTimersByTime(WEBSOCKET_TIMEOUT_MS);

    expect(FakeEventSource.instances).toHaveLength(0);
  });

  it('closes the event source when removed', () => {
    sessionStorage.setItem(TRANSPORT_STORAGE_KEY, 'sse');
    attach();

    element.remove();

    expect(FakeEventSource.instances[0].close).toHaveBeenCalled();
  });
});
