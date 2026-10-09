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

import { type Mock } from 'vitest';
import { Application } from '@hotwired/stimulus';
import { session } from '@hotwired/turbo';
import { nextFrame } from 'core-common/testing/timing';
import PollForChangesController from './poll-for-changes.controller';

describe('PollForChangesController', () => {
  const EVENT = 'op-dispatched:meeting-changed';
  const INTERVAL_MS = 10_000;

  let application:Application;
  let fixture:HTMLElement;
  let fetchMock:Mock<typeof fetch>;

  const render = async (eventValue = EVENT):Promise<void> => {
    // Only the polling interval is faked; Stimulus connects in an animation frame.
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] });
    fixture.innerHTML = `
      <div data-controller="poll-for-changes"
           data-poll-for-changes-url-value="/meetings/1/check_for_updates"
           data-poll-for-changes-interval-value="${INTERVAL_MS}"
           data-poll-for-changes-reference-value="ref-1"
           data-poll-for-changes-event-value="${eventValue}">
      </div>`;
    await nextFrame();
  };

  const fetchedUrls = ():string[] => fetchMock.mock.calls.map(([url]) => url as string);

  beforeEach(() => {
    fixture = document.createElement('div');
    document.body.appendChild(fixture);
    fetchMock = vi.fn<typeof fetch>(() => Promise.resolve(new Response(null, { status: 204 })));
    vi.stubGlobal('fetch', fetchMock);

    application = Application.start();
    application.register('poll-for-changes', PollForChangesController);
  });

  afterEach(async () => {
    vi.useRealTimers();
    fixture.remove();
    // Let Stimulus observe the removal and disconnect the controller before stopping.
    await nextFrame();
    application.stop();
    vi.unstubAllGlobals();
  });

  it('checks for updates right away on a change event', async () => {
    await render();

    document.dispatchEvent(new CustomEvent(EVENT));

    expect(fetchedUrls()).toEqual([`${window.location.origin}/meetings/1/check_for_updates?reference=ref-1`]);
  });

  it('ignores change events caused by a request of this tab', async () => {
    (session as unknown as { recentRequests:{ add(id:string):void } }).recentRequests.add('own-request');
    await render();

    document.dispatchEvent(new CustomEvent(EVENT, { detail: { requestId: 'own-request' } }));

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('checks for updates caused by requests of other tabs', async () => {
    (session as unknown as { recentRequests:{ add(id:string):void } }).recentRequests.add('own-request');
    await render();

    document.dispatchEvent(new CustomEvent(EVENT, { detail: { requestId: 'other-request' } }));

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('does not poll when an event is configured', async () => {
    await render();

    vi.advanceTimersByTime(INTERVAL_MS * 2);

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('polls and ignores change events when no event is configured', async () => {
    await render('');

    document.dispatchEvent(new CustomEvent(EVENT));

    expect(fetchMock).not.toHaveBeenCalled();

    vi.advanceTimersByTime(INTERVAL_MS);

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('stops listening once an update was shown', async () => {
    const notice = '<turbo-stream action="remove" target="no-such-element"></turbo-stream>';
    fetchMock.mockImplementation(() => Promise.resolve(new Response(notice, { status: 200 })));
    await render();

    document.dispatchEvent(new CustomEvent(EVENT));
    await nextFrame();
    document.dispatchEvent(new CustomEvent(EVENT));

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});
