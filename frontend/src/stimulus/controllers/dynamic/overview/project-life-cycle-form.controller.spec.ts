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
import type ProjectLifeCycleFormControllerType from './project-life-cycle-form.controller';

describe('Project life cycle form controller', () => {
  let ctx:StimulusTestContext;
  let ProjectLifeCycleFormController:typeof ProjectLifeCycleFormControllerType;
  let utcDateToISODateString:Mock;
  let timezone:{ utcDateToISODateString:Mock };
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: ProjectLifeCycleFormController } = await import('./project-life-cycle-form.controller'));
  });

  beforeEach(async () => {
    utcDateToISODateString = vi.fn((date:Date) => date.toISOString().slice(0, 10));
    timezone = { utcDateToISODateString };
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({ services: { timezone } }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'overview--project-life-cycle-form': ProjectLifeCycleFormController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  async function renderForm() {
    await ctx.mount(`
      <form data-controller="overview--project-life-cycle-form" action="/projects/1/life_cycle">
        <input type="text" data-overview--project-life-cycle-form-target="startDate" value="">
        <input type="text" data-overview--project-life-cycle-form-target="finishDate" value="">
        <input type="text" data-overview--project-life-cycle-form-target="duration" value="">
      </form>
    `);
    return ctx.getController<ProjectLifeCycleFormControllerType>('overview--project-life-cycle-form');
  }

  function flatpickrDatesChanged(dates:Date[]) {
    document.dispatchEvent(new CustomEvent('date-picker:flatpickr-dates-changed', { detail: { dates } }));
  }

  it('binds the declared timezone service after connect', async () => {
    const controller = await renderForm();

    await waitFor(() => { expect(controller.timezone).toBe(timezone); });
  });

  it('writes the changed flatpickr dates into the date fields', async () => {
    const controller = await renderForm();
    await waitFor(() => { expect(controller.timezone).toBe(timezone); });

    flatpickrDatesChanged([new Date('2026-06-01'), new Date('2026-06-11')]);

    const [startDate, finishDate] = Array.from(ctx.container.querySelectorAll('input'));
    expect(startDate.value).toBe('2026-06-01');
    expect(finishDate.value).toBe('2026-06-11');
    expect(startDate.classList.contains('op-datepicker-modal--date-field_current')).toBe(true);
  });

  it('ignores flatpickr events when disconnected before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    await renderForm();
    const form = ctx.container.querySelector('form')!;
    const startDate = ctx.container.querySelector('input')!;

    flatpickrDatesChanged([new Date('2026-06-01'), new Date('2026-06-11')]);
    expect(startDate.value).toBe('');

    form.remove();
    await ctx.nextFrame();

    resolveContext({ services: { timezone } });
    await ctx.nextFrame();

    flatpickrDatesChanged([new Date('2026-06-01'), new Date('2026-06-11')]);

    expect(startDate.value).toBe('');
    expect(utcDateToISODateString).not.toHaveBeenCalled();
  });
});
