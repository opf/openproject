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
      <turbo-frame id="content-frame" disabled>
        <div data-controller="work-packages--date-picker--preview">
          <form action="/work_packages/dialog" data-work-packages--date-picker--preview-target="form">
            <input type="text" id="work_package_start_date" name="work_package[start_date]" value=""
                   data-work-packages--date-picker--preview-target="fieldInput">
          </form>
        </div>
      </turbo-frame>
    `);
    return ctx.getController<PreviewControllerType>('work-packages--date-picker--preview');
  }

  async function renderDateForm({
    startDate = '',
    dueDate = '',
    duration = '',
    highlighted = 'start_date',
    scheduleManually = true,
    touched = [],
  }:{
    startDate?:string,
    dueDate?:string,
    duration?:string,
    highlighted?:'start_date'|'due_date'|'duration',
    scheduleManually?:boolean,
    touched?:string[],
  } = {}) {
    const field = (name:string, value:string) => `
      <input type="text" id="work_package_${name}" name="work_package[${name}]" value="${value}"
             class="${highlighted === name ? 'op-datepicker-modal--date-field_current' : ''}"
             data-work-packages--date-picker--preview-target="fieldInput">
      <input type="hidden" value="${value}" data-referrer-field="${name}"
             data-work-packages--date-picker--preview-target="initialValueInput">
      <input type="hidden" value="${touched.includes(name) ? 'true' : 'false'}" data-referrer-field="${name}"
             data-work-packages--date-picker--preview-target="touchedFieldInput">
    `;

    await ctx.mount(`
      <turbo-frame id="content-frame" disabled>
        <div data-controller="work-packages--date-picker--preview"
             data-work-packages--date-picker--preview-schedule-manually-value="${scheduleManually}">
          <form action="/work_packages/dialog" data-work-packages--date-picker--preview-target="form">
            ${field('start_date', startDate)}
            ${field('due_date', dueDate)}
            ${field('duration', duration)}
          </form>
        </div>
      </turbo-frame>
    `);

    const controller = ctx.getController<PreviewControllerType>('work-packages--date-picker--preview');
    await waitFor(() => { expect(controller.timezone).toBe(timezone); });
    return controller;
  }

  function flatpickrDatesChanged(dates:Date[]) {
    document.dispatchEvent(new CustomEvent('date-picker:flatpickr-dates-changed', { detail: { dates } }));
  }

  async function morphFrame(src:string) {
    await renderDialog();
    const turboFrame = ctx.container.querySelector('turbo-frame')!;
    turboFrame.setAttribute('src', src);

    const currentElement = document.createElement('turbo-frame');
    currentElement.innerHTML = '<opce-test-marker data-marker="old"></opce-test-marker><div data-marker="old">old</div>';
    const newElement = document.createElement('turbo-frame');
    newElement.innerHTML = '<opce-test-marker data-marker="new"></opce-test-marker><div data-marker="new">new</div>';

    const detail:{ render?:(current:Element, next:Element) => void } = {};
    turboFrame.dispatchEvent(new CustomEvent('turbo:before-frame-render', { detail }));
    detail.render!(currentElement, newElement);

    return currentElement;
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

  it('marks a valid field update pending until the preview is rendered', async () => {
    const controller = await renderDialog();
    const form = ctx.container.querySelector<HTMLFormElement>('form')!;
    const input = ctx.container.querySelector<HTMLInputElement>('#work_package_start_date')!;
    input.value = '2026-06-11';

    controller.inputChanged({ target: input } as unknown as Event);

    expect(form.dataset.datepickerPreviewPending).toBe('true');

    controller.afterRendering({});

    expect(form.dataset.datepickerPreviewPending).toBeUndefined();
  });

  it('does not mark an invalid date pending when no preview is scheduled', async () => {
    const controller = await renderDialog();
    const form = ctx.container.querySelector<HTMLFormElement>('form')!;
    const input = ctx.container.querySelector<HTMLInputElement>('#work_package_start_date')!;
    input.value = 'invalid';

    controller.inputChanged({ target: input } as unknown as Event);

    expect(form.dataset.datepickerPreviewPending).toBeUndefined();
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

  it('skips morphing an OPCE-* node when scheduling has not changed', async () => {
    const currentElement = await morphFrame('/work_packages/123/dialog/preview');

    expect(currentElement.querySelector('opce-test-marker')!.getAttribute('data-marker')).toBe('old');
    expect(currentElement.querySelector('div')!.getAttribute('data-marker')).toBe('new');
  });

  it('replaces an OPCE-* node when scheduling has changed', async () => {
    const currentElement = await morphFrame('/work_packages/123/dialog/preview?schedule_manually=true');

    expect(currentElement.querySelector('opce-test-marker')!.getAttribute('data-marker')).toBe('new');
  });

  it('keeps morphing siblings that follow a replaced OPCE-* node', async () => {
    const currentElement = await morphFrame('/work_packages/123/dialog/preview?schedule_manually=true');

    expect(currentElement.querySelectorAll('opce-test-marker')).toHaveLength(1);
    expect(currentElement.querySelectorAll('div')).toHaveLength(1);
    expect(currentElement.querySelector('div')!.getAttribute('data-marker')).toBe('new');
  });

  it('clears an earlier due date and duration when the start date moves past it', async () => {
    const controller = await renderDateForm({
      startDate: '2026-06-10',
      dueDate: '2026-06-12',
      duration: '3',
    });

    controller.changeStartDate(new Date('2026-06-13'));

    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_start_date')!.value).toBe('2026-06-13');
    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_due_date')!.value).toBe('');
    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_duration')!.value).toBe('');
  });

  it('clears a later start date and duration when the due date moves before it', async () => {
    const controller = await renderDateForm({
      startDate: '2026-06-10',
      dueDate: '2026-06-12',
      duration: '3',
      highlighted: 'due_date',
    });

    controller.changeDueDate(new Date('2026-06-09'));

    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_start_date')!.value).toBe('');
    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_due_date')!.value).toBe('2026-06-09');
    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_duration')!.value).toBe('');
  });

  it('turns a lone due date into the start of a range when a later date is selected', async () => {
    await renderDateForm({ dueDate: '2026-06-12' });

    flatpickrDatesChanged([new Date('2026-06-12'), new Date('2026-06-15')]);

    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_start_date')!.value).toBe('2026-06-12');
    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_due_date')!.value).toBe('2026-06-15');
    expect(ctx.container.querySelector('#work_package_due_date')).toHaveClass('op-datepicker-modal--date-field_current');
  });

  it('turns a lone start date into the end of a range when an earlier date is selected', async () => {
    await renderDateForm({ startDate: '2026-06-12', highlighted: 'due_date' });

    flatpickrDatesChanged([new Date('2026-06-09'), new Date('2026-06-12')]);

    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_start_date')!.value).toBe('2026-06-09');
    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_due_date')!.value).toBe('2026-06-12');
    expect(ctx.container.querySelector('#work_package_start_date')).toHaveClass('op-datepicker-modal--date-field_current');
  });

  it('uses the due date when duration is highlighted and only a start date exists', async () => {
    await renderDateForm({ startDate: '2026-06-12', highlighted: 'duration' });

    flatpickrDatesChanged([new Date('2026-06-15')]);

    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_start_date')!.value).toBe('2026-06-12');
    expect(ctx.container.querySelector<HTMLInputElement>('#work_package_due_date')!.value).toBe('2026-06-15');
  });

  it('keeps a lone highlighted date in single-date calendar mode', async () => {
    await renderDateForm({ dueDate: '2026-06-12', highlighted: 'due_date' });
    let calendarMode:string|undefined;
    const calendarUpdate = (event:Event) => {
      calendarMode = (event as CustomEvent<{ mode:string }>).detail.mode;
    };
    document.addEventListener('date-picker:flatpickr-set-values', calendarUpdate, { once: true });

    flatpickrDatesChanged([new Date('2026-06-15')]);

    expect(calendarMode).toBe('single');
  });
});
