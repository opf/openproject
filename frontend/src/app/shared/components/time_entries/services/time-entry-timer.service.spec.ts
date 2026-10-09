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

import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OngoingTimer } from 'core-app/shared/components/time_entries/services/ongoing-timer';
import {
  TIMER_CHANGED_EVENT,
  TimeEntryTimerService,
} from 'core-app/shared/components/time_entries/services/time-entry-timer.service';

if (!customElements.get('opce-principal')) {
  customElements.define('opce-principal', class extends HTMLElement {});
}

describe('TimeEntryTimerService', () => {
  let service:TimeEntryTimerService;
  let fixture:HTMLElement;
  let post:ReturnType<typeof vi.fn>;
  let ongoingOnServer:unknown[];
  let request:ReturnType<typeof vi.fn>;
  let addWarning:ReturnType<typeof vi.fn>;

  const timer:OngoingTimer = {
    id: '7',
    createdAt: '2026-10-09T10:00:00Z',
    entityId: '42',
    entityName: '#42: Some work',
  };

  const renderPage = (ongoing:OngoingTimer|null) => {
    const payload = ongoing ? `<div data-ongoing-timer='${JSON.stringify(ongoing)}'></div>` : '';
    fixture.innerHTML = `
      <opce-principal class="op-top-menu-user-avatar"></opce-principal>
      <turbo-frame id="my_timers">${payload}</turbo-frame>
    `;
  };

  const badgeCount = ():number => fixture.querySelectorAll('.op-principal--timer').length;
  const settle = ():Promise<void> => new Promise((resolve) => { setTimeout(resolve); });

  beforeEach(() => {
    fixture = document.createElement('div');
    document.body.appendChild(fixture);

    ongoingOnServer = [];
    post = vi.fn(() => of({}));
    const filtered = vi.fn(() => ({ get: () => of({ elements: [...ongoingOnServer] }) }));
    request = vi.fn(() => Promise.resolve());
    addWarning = vi.fn();

    TestBed.configureTestingModule({
      providers: [
        TimeEntryTimerService,
        { provide: ApiV3Service, useValue: { time_entries: { post, filtered } } },
        { provide: ToastService, useValue: { addWarning } },
        { provide: TurboRequestsService, useValue: { request } },
        { provide: PathHelperService, useValue: { timeEntryEditDialog: (id:string) => `/time_entries/${id}/dialog` } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalService, useValue: {} },
      ],
    });

    service = TestBed.inject(TimeEntryTimerService);
  });

  afterEach(() => fixture.remove());

  it('reads the running timer from the menu frame and shows the avatar badge', async () => {
    renderPage(timer);

    service.initialize();
    await settle();

    expect(service.timer$.value).toEqual(timer);
    expect(badgeCount()).toBe(1);
  });

  it('shows no badge without a running timer', async () => {
    renderPage(null);

    service.initialize();
    await settle();

    expect(service.timer$.value).toBeNull();
    expect(badgeCount()).toBe(0);
  });

  it('registers its document listeners only once across repeated initialization', async () => {
    renderPage(timer);
    const addEventListener = vi.spyOn(document, 'addEventListener');

    service.initialize();
    service.initialize();
    service.initialize();
    await settle();

    expect(addEventListener.mock.calls.filter(([name]) => name === 'turbo:frame-load')).toHaveLength(1);
    expect(badgeCount()).toBe(1);
    addEventListener.mockRestore();
  });

  it('re-reads the state when the menu frame reloads', async () => {
    renderPage(timer);
    service.initialize();
    await settle();

    fixture.querySelector('[data-ongoing-timer]')!.remove();
    fixture.querySelector('#my_timers')!.dispatchEvent(new Event('turbo:frame-load', { bubbles: true }));
    await settle();

    expect(service.timer$.value).toBeNull();
    expect(badgeCount()).toBe(0);
  });

  it('opens the edit dialog of the running timer on stop', async () => {
    renderPage(timer);
    service.initialize();
    ongoingOnServer = [{
      id: '7',
      createdAt: '2026-10-09T10:00:00Z',
      entity: { href: '/api/v3/work_packages/42', name: 'Some work', $link: { displayId: '42' } },
    }];

    await service.stop();

    expect(request).toHaveBeenCalledWith('/time_entries/7/dialog', { method: 'GET' });
  });

  it('warns on stop when another tab already stopped the timer', async () => {
    renderPage(timer);
    service.initialize();

    await service.stop();

    expect(addWarning).toHaveBeenCalledWith('js.timer.timer_already_stopped');
    expect(request).not.toHaveBeenCalled();
  });

  it('creates a timer and announces the change when none is running', async () => {
    renderPage(null);
    service.initialize();
    const listener = vi.fn();
    document.addEventListener(TIMER_CHANGED_EVENT, listener);

    await service.start({ id: '42', href: '/api/v3/work_packages/42' } as WorkPackageResource);

    expect(post).toHaveBeenCalledTimes(1);
    expect(listener).toHaveBeenCalledTimes(1);
    document.removeEventListener(TIMER_CHANGED_EVENT, listener);
  });
});
