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
import type PreviewControllerType from './preview.controller';

describe('Date picker preview controller', () => {
  let ctx:StimulusTestContext;
  let PreviewController:typeof PreviewControllerType;
  let utcDateToISODateString:Mock;
  let timezone:{ utcDateToISODateString:Mock, utcDatesToISODateStrings:Mock };
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: PreviewController } = await import('./preview.controller'));
  });

  beforeEach(async () => {
    utcDateToISODateString = vi.fn((date:Date) => date.toISOString().slice(0, 10));
    timezone = {
      utcDateToISODateString,
      utcDatesToISODateStrings: vi.fn((dates:Date[]) => dates.map((date) => date.toISOString().slice(0, 10))),
    };
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({ services: { timezone } }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'work-packages--date-picker--preview': PreviewController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderDialog() {
    await ctx.mount(`
      <div data-controller="work-packages--date-picker--preview">
        <form action="/work_packages/dialog" data-work-packages--date-picker--preview-target="form">
          <input type="text" id="work_package_start_date" name="work_package[start_date]" value=""
                 data-work-packages--date-picker--preview-target="fieldInput">
        </form>
      </div>
    `);
    return ctx.getController<PreviewControllerType>('work-packages--date-picker--preview');
  }

  function flatpickrDatesChanged(dates:Date[]) {
    document.dispatchEvent(new CustomEvent('date-picker:flatpickr-dates-changed', { detail: { dates } }));
  }

  it('binds the declared timezone service after connect', async () => {
    const controller = await renderDialog();

    await waitFor(() => { expect(controller.timezone).toBe(timezone); });
  });

  it('writes the changed flatpickr date into the start date field', async () => {
    const controller = await renderDialog();
    await waitFor(() => { expect(controller.timezone).toBe(timezone); });

    flatpickrDatesChanged([new Date('2026-06-11')]);

    const input = ctx.container.querySelector<HTMLInputElement>('#work_package_start_date')!;
    expect(input.value).toBe('2026-06-11');
    expect(utcDateToISODateString).toHaveBeenCalled();
  });

  it('ignores flatpickr events when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    await renderDialog();
    const root = ctx.container.querySelector('[data-controller="work-packages--date-picker--preview"]')!;
    const input = ctx.container.querySelector<HTMLInputElement>('#work_package_start_date')!;

    flatpickrDatesChanged([new Date('2026-06-11')]);
    expect(input.value).toBe('');

    root.remove();
    await ctx.nextFrame();

    resolveContext({ services: { timezone } });
    await ctx.nextFrame();

    flatpickrDatesChanged([new Date('2026-06-11')]);

    expect(input.value).toBe('');
    expect(utcDateToISODateString).not.toHaveBeenCalled();
  });
});
