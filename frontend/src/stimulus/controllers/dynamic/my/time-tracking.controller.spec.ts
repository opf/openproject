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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { waitFor } from '@testing-library/dom';
import { type ActionEvent } from '@hotwired/stimulus';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type MyTimeTrackingControllerType from './time-tracking.controller';

describe('My time tracking controller', () => {
  let ctx:StimulusTestContext;
  let MyTimeTrackingController:typeof MyTimeTrackingControllerType;
  let request:Mock;
  let myTimeTrackingRefresh:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: MyTimeTrackingController } = await import('./time-tracking.controller'));
  });

  beforeEach(async () => {
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    myTimeTrackingRefresh = vi.fn().mockReturnValue('/my/time_tracking/refresh?date=2026-06-01');
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: {
          turboRequests: { request },
          pathHelperService: {
            timeEntryDialog: () => '/time_entries/dialog',
            myTimeTrackingRefresh,
          },
        },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'my--time-tracking': MyTimeTrackingController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  // The calendar view needs FullCalendar; the list view exercises the
  // service wiring without it.
  async function renderListView() {
    await ctx.mount(`
      <div data-controller="my--time-tracking"
           data-my--time-tracking-view-mode-value="list"
           data-my--time-tracking-mode-value="week"></div>
    `);
    return ctx.getController<MyTimeTrackingControllerType>('my--time-tracking');
  }

  function dialogClosed(detail:object) {
    document.dispatchEvent(new CustomEvent('dialog:close', { detail }));
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderListView();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
    });
  });

  it('requests the time entry dialog for a new time entry', async () => {
    const controller = await renderListView();

    void controller.newTimeEntry({ params: { date: '2026-06-01' } } as unknown as ActionEvent);

    await waitFor(() => {
      expect(request).toHaveBeenCalledWith(
        '/time_entries/dialog?onlyMe=true&date=2026-06-01',
        { method: 'GET' },
      );
    });
  });

  it('refreshes the list when the time entry dialog was submitted', async () => {
    const controller = await renderListView();
    await waitFor(() => { expect(controller.turboRequests).toBeDefined(); });

    dialogClosed({
      dialog: { id: 'time-entry-dialog' },
      additional: { spent_on: '2026-06-01' },
      submitted: true,
    });

    await waitFor(() => {
      expect(request).toHaveBeenCalledWith('/my/time_tracking/refresh?date=2026-06-01', { method: 'GET' });
    });
    expect(myTimeTrackingRefresh).toHaveBeenCalledWith('2026-06-01', 'list', 'week');
  });

  it('ignores dialog close events arriving before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    await renderListView();
    const root = ctx.container.querySelector('[data-controller="my--time-tracking"]')!;

    dialogClosed({
      dialog: { id: 'time-entry-dialog' },
      additional: { spent_on: '2026-06-01' },
      submitted: true,
    });

    root.remove();
    await ctx.nextFrame();

    resolveContext({
      services: {
        turboRequests: { request },
        pathHelperService: {
          timeEntryDialog: () => '/time_entries/dialog',
          myTimeTrackingRefresh,
        },
      },
    });
    await ctx.nextFrame();

    expect(request).not.toHaveBeenCalled();
  });
});
