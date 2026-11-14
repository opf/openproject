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

import type { HocuspocusProvider, onAwarenessUpdateParameters } from '@hocuspocus/provider';
import { LiveCollaborationManager } from 'core-stimulus/helpers/live-collaboration-helpers';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import LiveEventsController from './live-events.controller';

type AwarenessListener = (data:onAwarenessUpdateParameters) => void;
interface PendingRequest { resolve:(body:string) => void; reject:(error:Error) => void }

const userA = { id: '1', name: 'A', avatarUrl: '' };
const userB = { id: '2', name: 'B', avatarUrl: '' };
const userC = { id: '3', name: 'C', avatarUrl: '' };

describe('LiveEventsController', () => {
  let ctx:StimulusTestContext;
  let provider:HocuspocusProvider;
  let awarenessListener:AwarenessListener;
  let pendingRequests:Map<string, PendingRequest>;
  let streamRenders:string[];

  const recordStreamRender = (event:Event) => {
    streamRenders.push((event.target as Element).querySelector('template')!.content.textContent);
  };

  const emitAwareness = (users:typeof userA[]) => {
    awarenessListener({
      states: users.map((user, index) => ({ clientId: index + 1, user })),
    });
  };

  const flushDebounce = () => vi.advanceTimersByTime(1000);

  const respond = (userIds:string) => {
    pendingRequests.get(userIds)!.resolve(
      `<turbo-stream action="update" target="live-users"><template>${userIds}</template></turbo-stream>`,
    );
  };

  const fail = async (userIds:string) => {
    pendingRequests.get(userIds)!.reject(new TypeError('Failed to fetch'));
    await ctx.nextFrame();
  };

  const renderedUsers = () => ctx.container.querySelector('#live-users')!.textContent;

  beforeEach(async () => {
    pendingRequests = new Map();
    streamRenders = [];
    document.addEventListener('turbo:before-stream-render', recordStreamRender);
    vi.spyOn(window, 'fetch').mockImplementation((input, init) => {
      const userIds = new URL(input as string, window.location.origin).searchParams.getAll('user_ids[]').join(',');
      return new Promise((resolve, reject) => {
        init?.signal?.addEventListener('abort', () => reject(new DOMException('Aborted', 'AbortError')));
        pendingRequests.set(userIds, {
          resolve: (body) => resolve(new Response(body, { status: 200 })),
          reject,
        });
      });
    });
    vi.spyOn(console, 'error').mockImplementation(() => undefined);

    provider = {
      on: (event:string, listener:AwarenessListener) => {
        if (event === 'awarenessUpdate') awarenessListener = listener;
      },
      off: () => undefined,
      destroy: () => undefined,
    } as unknown as HocuspocusProvider;
    LiveCollaborationManager.initializeYjsProvider(provider, { destroy: () => undefined } as never, 'doc');

    ctx = await setupStimulusTest({ controllers: { 'documents--live-events': LiveEventsController } });
    await ctx.mount('<div data-controller="documents--live-events"><div id="live-users"></div></div>');
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
  });

  afterEach(() => {
    document.removeEventListener('turbo:before-stream-render', recordStreamRender);
    vi.useRealTimers();
    vi.restoreAllMocks();
    ctx.dispose();
    LiveCollaborationManager.destroyIfOwner(provider);
  });

  it('does not render an outdated render_avatars response that arrives last', async () => {
    emitAwareness([userA]);
    flushDebounce();
    emitAwareness([userA, userB]);
    flushDebounce();

    respond('1,2');
    await vi.waitFor(() => expect(renderedUsers()).toBe('1,2'));
    respond('1');

    emitAwareness([userA, userB, userC]);
    flushDebounce();
    respond('1,2,3');
    await vi.waitFor(() => expect(renderedUsers()).toBe('1,2,3'));

    expect(streamRenders).toEqual(['1,2', '1,2,3']);
  });

  it('requests the avatars again on the next awareness update after a failed request', async () => {
    emitAwareness([userA, userB]);
    flushDebounce();
    await fail('1,2');

    emitAwareness([userA, userB]);
    flushDebounce();
    respond('1,2');

    await vi.waitFor(() => expect(renderedUsers()).toBe('1,2'));
  });

  it('keeps the newer users when a request fails while the next update is pending', async () => {
    emitAwareness([userA, userB]);
    flushDebounce();

    emitAwareness([userA, userB, userC]);
    await fail('1,2');
    flushDebounce();
    respond('1,2,3');

    await vi.waitFor(() => expect(renderedUsers()).toBe('1,2,3'));
  });
});
