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

import { waitFor } from '@testing-library/dom';
import { type ActionEvent } from '@hotwired/stimulus';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type MyWorkControllerType from './work.controller';

describe('My work controller', () => {
  let ctx:StimulusTestContext;
  let MyWorkController:typeof MyWorkControllerType;
  let request:Mock;
  let myWorkRefresh:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: MyWorkController } = await import('./work.controller'));
  });

  beforeEach(async () => {
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    myWorkRefresh = vi.fn().mockReturnValue('/my/work/refresh?date=2026-06-01');
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: {
          turboRequests: { request },
          pathHelperService: {
            timeEntryDialog: () => '/time_entries/dialog',
            myWorkRefresh,
          },
        },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'my--work': MyWorkController },
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
      <div data-controller="my--work"
           data-my--work-view-mode-value="list"
           data-my--work-mode-value="week"></div>
    `);
    return ctx.getController<MyWorkControllerType>('my--work');
  }

  // The calendar itself needs FullCalendar, which only starts with a target; without one the
  // view mode still picks the branch that brings the view back after logging time.
  async function renderCalendarViewInFrame(frameAttributes = '') {
    await ctx.mount(`
      <turbo-frame id="my-work-view" ${frameAttributes}>
        <div data-controller="my--work"
             data-my--work-view-mode-value="calendar"
             data-my--work-mode-value="week"></div>
      </turbo-frame>
    `);
    const controller = ctx.getController<MyWorkControllerType>('my--work');
    await waitFor(() => { expect(controller.turboRequests).toBeDefined(); });

    return ctx.container.querySelector('turbo-frame')!;
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
        false,
        // named, so that clicking twice before the dialog arrives drops the first request
        'time-entry-dialog',
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
      expect(request).toHaveBeenCalledWith('/my/work/refresh?date=2026-06-01', { method: 'GET' });
    });
    expect(myWorkRefresh).toHaveBeenCalledWith('2026-06-01', 'list', 'week', 'all');
  });

  it('brings the calendar back through its frame instead of reloading the page', async () => {
    const frame = await renderCalendarViewInFrame();

    dialogClosed({ dialog: { id: 'time-entry-dialog' }, submitted: true });

    await waitFor(() => {
      expect(frame.getAttribute('src')).toEqual(window.location.href);
    });
  });

  it('reloads a frame that already knows its own source, as the my page widget does', async () => {
    const frame = await renderCalendarViewInFrame('src="/widgets/time_entries_current_user"');
    // Turbo is not registered here, so the element never upgraded and has no reload of its own.
    const reload = vi.fn();
    (frame as unknown as { reload:() => void }).reload = reload;

    dialogClosed({ dialog: { id: 'time-entry-dialog' }, submitted: true });

    await waitFor(() => { expect(reload).toHaveBeenCalled(); });
    // its own source, not the page it happens to sit on
    expect(frame.getAttribute('src')).toEqual('/widgets/time_entries_current_user');
  });

  it('ignores dialog close events arriving before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    await renderListView();
    const root = ctx.container.querySelector('[data-controller="my--work"]')!;

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
          myWorkRefresh,
        },
      },
    });
    await ctx.nextFrame();

    expect(request).not.toHaveBeenCalled();
  });
});
