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
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type TimeEntryControllerType from './time-entry.controller';

describe('Time entry controller', () => {
  let ctx:StimulusTestContext;
  let TimeEntryController:typeof TimeEntryControllerType;
  let request:Mock;
  let timeEntriesUserTimezoneCaption:Mock;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: TimeEntryController } = await import('./time-entry.controller'));
  });

  beforeEach(async () => {
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    timeEntriesUserTimezoneCaption = vi.fn().mockReturnValue('/time_entries/user_timezone_caption/5');
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: {
          turboRequests: { request },
          pathHelperService: { timeEntriesUserTimezoneCaption },
        },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'time-entry': TimeEntryController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderForm() {
    await ctx.mount(`
      <div data-controller="time-entry">
        <form data-time-entry-target="form" data-refresh-form-url="/time_entries/refresh_form">
          <input name="time_entry[user_id]" value="5">
        </form>
      </div>
    `);
    return ctx.getController<TimeEntryControllerType>('time-entry');
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderForm();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
    });
  });

  it('requests the timezone caption when the user changes', async () => {
    const controller = await renderForm();
    const input = ctx.container.querySelector('input')!;

    void controller.userChanged({ currentTarget: input } as unknown as InputEvent);

    await waitFor(() => {
      expect(request).toHaveBeenCalledWith('/time_entries/user_timezone_caption/5', { method: 'GET' });
    });
    expect(timeEntriesUserTimezoneCaption).toHaveBeenCalledWith('5');
  });

  it('does not request when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const controller = await renderForm();
    const root = ctx.container.querySelector('[data-controller="time-entry"]')!;
    const input = ctx.container.querySelector('input')!;

    void controller.userChanged({ currentTarget: input } as unknown as InputEvent);
    await ctx.nextFrame();

    root.remove();
    await ctx.nextFrame();

    resolveContext({
      services: {
        turboRequests: { request },
        pathHelperService: { timeEntriesUserTimezoneCaption },
      },
    });
    await ctx.nextFrame();

    expect(request).not.toHaveBeenCalled();
  });
});
