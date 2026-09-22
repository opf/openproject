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

import * as Turbo from '@hotwired/turbo';
import type { MockInstance } from 'vitest';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type FiltersFormControllerType from './filters-form.controller';

interface VisitingSession {
  visit:(location:string, options:object) => void;
}

interface StatusRow {
  hidden:boolean;
  disabled:boolean;
  value:string;
}

const UNKNOWN_TO_SERVER:StatusRow = { hidden: true, disabled: false, value: '' };
const APPLIED_ON_SERVER:StatusRow = { hidden: false, disabled: true, value: '2' };

describe('Filters form pending rows', () => {
  let ctx:StimulusTestContext;
  let Controller:typeof FiltersFormControllerType;
  let originalUrl:string;
  let visit:MockInstance<VisitingSession['visit']>;

  beforeAll(async () => {
    ({ default: Controller } = await import('./filters-form.controller'));
  });

  beforeEach(() => {
    originalUrl = window.location.href;
    visit = vi.spyOn(Turbo.session as unknown as VisitingSession, 'visit').mockImplementation(() => undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    ctx.dispose();
    window.history.replaceState(window.history.state, '', originalUrl);
  });

  function form(statusRow:StatusRow) {
    return `<div data-controller="filter--filters-form"
      data-filter--filters-form-turbo-frame-request-value="backlogs_container">
      <select aria-label="Add filter" data-filter--filters-form-target="addFilterSelect">
        <option value=""></option>
        <option value="status_id" ${statusRow.disabled ? 'disabled' : ''}>Status</option>
        <option value="subject">Subject</option>
      </select>
      <div data-filter-name="status_id" data-filter-type="list" ${statusRow.hidden ? 'hidden' : ''}
        data-filter--filters-form-target="filter">
        <select aria-label="Status operator" data-filter-name="status_id" data-filter--filters-form-target="operator">
          <option value="=">is (OR)</option>
        </select>
        <div data-filter-name="status_id" data-filter-autocomplete="true"
          data-filter--filters-form-target="filterValueContainer">
          <input type="hidden" name="value" value="${statusRow.value}">
        </div>
      </div>
      <div data-filter-name="subject" data-filter-type="string" hidden data-filter--filters-form-target="filter">
        <select aria-label="Subject operator" data-filter-name="subject" data-filter--filters-form-target="operator">
          <option value="~">contains</option>
        </select>
        <div data-filter-name="subject" data-filter--filters-form-target="filterValueContainer">
          <input type="text" name="value" value="" aria-label="Subject value"
            data-filter-name="subject" data-filter--filters-form-target="simpleValue">
        </div>
      </div>
    </div>`;
  }

  async function mount(html = form(UNKNOWN_TO_SERVER)) {
    ctx = await setupStimulusTest({ controllers: { 'filter--filters-form': Controller } });
    await ctx.mount(html);
    return ctx.getController<FiltersFormControllerType>('filter--filters-form');
  }

  function host():HTMLElement {
    return ctx.container.querySelector<HTMLElement>('[data-controller]')!;
  }

  // getByRole returns HTMLElement; the generic narrows it where `.value` is read or written.
  const addFilterSelect = () => ctx.screen.getByRole<HTMLSelectElement>('combobox', { name: 'Add filter' });
  const statusOperator = () => ctx.screen.getByRole('combobox', { name: 'Status operator', hidden: true });
  const subjectOperator = () => ctx.screen.getByRole('combobox', { name: 'Subject operator', hidden: true });
  const subjectRow = () => subjectOperator().closest<HTMLElement>('[data-filter--filters-form-target="filter"]')!;
  const statusOption = () => ctx.screen.getByRole<HTMLOptionElement>('option', { name: 'Status', hidden: true });
  const subjectOption = () => ctx.screen.getByRole<HTMLOptionElement>('option', { name: 'Subject', hidden: true });
  const statusValue = () => ctx.container.querySelector<HTMLInputElement>('[data-filter-name="status_id"] input[name="value"]')!;
  const subjectValue = () => ctx.screen.getByRole<HTMLInputElement>('textbox', { name: 'Subject value', hidden: true });

  function addStatusFilter(controller:FiltersFormControllerType) {
    addFilterSelect().value = 'status_id';
    controller.addFilterByName('status_id');
  }

  function selectStatus(id:string) {
    statusValue().value = id;
  }

  function rerenderFromServer(statusRow:StatusRow) {
    const template = document.createElement('template');
    template.innerHTML = form(statusRow);
    Turbo.morphElements(host(), template.content.firstElementChild!);
  }

  it('keeps an added row visible through a re-render that does not know it yet', async () => {
    const controller = await mount();

    addStatusFilter(controller);
    expect(statusOperator()).toBeVisible();
    expect(statusOption()).toBeDisabled();

    // Two morphs: Idiomorph syncs the incoming attributes (hidden) before it removes the ones
    // only the current element has (the marker), so a single morph passes even when the
    // marker itself is not protected.
    rerenderFromServer(UNKNOWN_TO_SERVER);
    rerenderFromServer(UNKNOWN_TO_SERVER);

    expect(statusOperator()).toBeVisible();
    expect(statusOption()).toBeDisabled();
  });

  it('hands the row to the server once it has been submitted with a value', async () => {
    const controller = await mount();
    addStatusFilter(controller);

    selectStatus('2');
    controller.autocompleteSendForm();
    rerenderFromServer(APPLIED_ON_SERVER);

    expect(statusOperator()).toBeVisible();
    expect(statusOption()).toBeDisabled();
    expect(statusValue()).toHaveValue('2');
  });

  it('no longer protects a submitted row from a response that drops it', async () => {
    const controller = await mount();
    addStatusFilter(controller);

    selectStatus('2');
    controller.autocompleteSendForm();
    rerenderFromServer(UNKNOWN_TO_SERVER);

    expect(statusOperator()).not.toBeVisible();
    expect(statusOption()).toBeEnabled();
  });

  it('lets the server own a row that was removed again', async () => {
    const controller = await mount();
    addStatusFilter(controller);

    controller.removeFilter({ params: { filterName: 'status_id' } });
    rerenderFromServer(UNKNOWN_TO_SERVER);

    expect(statusOperator()).not.toBeVisible();
    expect(statusOption()).toBeEnabled();
  });

  it('does not keep other rows from being hidden by the server', async () => {
    const controller = await mount();
    addStatusFilter(controller);

    // The operator select carries data-filter-name too, so the row is reached via its target attribute.
    subjectRow().hidden = false;
    expect(subjectOperator()).toBeVisible();

    rerenderFromServer(UNKNOWN_TO_SERVER);

    expect(subjectOperator()).not.toBeVisible();
    expect(statusOperator()).toBeVisible();
  });

  it('takes the add-filter option without the caller selecting it first', async () => {
    const controller = await mount();

    controller.addFilterByName('status_id');

    expect(statusOption()).toBeDisabled();
    expect(addFilterSelect()).toHaveValue('');
    expect(statusOperator()).toBeVisible();
  });

  it('drops an unsent row when a cached page is restored, keeping applied rows', async () => {
    // The server applied "subject ~ x": row visible, option taken, value present.
    const controller = await mount(form(UNKNOWN_TO_SERVER)
      .replace('data-filter-name="subject" data-filter-type="string" hidden', 'data-filter-name="subject" data-filter-type="string"')
      .replace('<option value="subject">Subject</option>', '<option value="subject" disabled>Subject</option>')
      .replace('<input type="text" name="value" value="" aria-label', '<input type="text" name="value" value="x" aria-label'));
    addStatusFilter(controller);

    // Turbo snapshots the page before the old controller disconnects, so the
    // restored markup carries the pending row next to the applied one.
    const cached = host().outerHTML;
    ctx.dispose();
    await mount(cached);

    expect(statusOperator()).not.toBeVisible();
    expect(statusOption()).toBeEnabled();
    expect(host().querySelector('[data-filter-pending]')).toBeNull();

    expect(subjectOperator()).toBeVisible();
    expect(subjectOption()).toBeDisabled();
    expect(subjectValue()).toHaveValue('x');
  });

  it('drops a typed but unsent value when a cached page is restored', async () => {
    const controller = await mount();
    addFilterSelect().value = 'subject';
    controller.addFilterByName('subject');
    subjectValue().value = 'unsent draft';

    // Turbo's snapshot clone carries live control values, not just markup. `element` is not
    // part of the published typings.
    const { element: cached } = Turbo.PageSnapshot.fromElement(host()).clone() as unknown as { element:HTMLElement };
    ctx.dispose();
    ctx = await setupStimulusTest({ controllers: { 'filter--filters-form': Controller } });
    ctx.container.append(cached);
    await ctx.nextFrame();
    const restored = ctx.getController<FiltersFormControllerType>('filter--filters-form');

    expect(subjectOperator()).not.toBeVisible();
    expect(subjectValue()).toHaveValue('');

    addFilterSelect().value = 'subject';
    restored.addFilterByName('subject');

    expect(subjectOperator()).toBeVisible();
    expect(visit).not.toHaveBeenCalled();
  });

  describe('with a date range row', () => {
    function dateRow(rangeValue:string) {
      return `<div data-controller="filter--filters-form"
        data-filter--filters-form-turbo-frame-request-value="backlogs_container">
        <select aria-label="Add filter" data-filter--filters-form-target="addFilterSelect">
          <option value=""></option>
          <option value="dates_interval">Dates interval</option>
        </select>
        <div data-filter-name="dates_interval" data-filter-type="date" hidden data-filter--filters-form-target="filter">
          <select aria-label="Dates interval operator" data-filter-name="dates_interval" data-filter--filters-form-target="operator">
            <option value="<>d">between</option>
          </select>
          <div data-filter-name="dates_interval" data-filter--filters-form-target="filterValueContainer">
            <input id="dates_interval" aria-label="Dates interval range" value="${rangeValue}"
              data-filter--filters-form-target="dateRange">
          </div>
        </div>
      </div>`;
    }

    const rangeOperator = () => ctx.screen.getByRole('combobox', { name: 'Dates interval operator', hidden: true });
    const rangeInput = () => ctx.screen.getByRole<HTMLInputElement>('textbox', { name: 'Dates interval range', hidden: true });

    function rerenderDateRow() {
      const template = document.createElement('template');
      template.innerHTML = dateRow('-');
      Turbo.morphElements(host(), template.content.firstElementChild!);
    }

    async function addDatesInterval(rangeValue:string) {
      const controller = await mount(dateRow(rangeValue));
      addFilterSelect().value = 'dates_interval';
      controller.addFilterByName('dates_interval');
      return controller;
    }

    // The picker renders an empty range as "-"; a cleared picker leaves "".
    it.each(['-', ''])('keeps a range row pending while its input holds %j', async (rangeValue) => {
      const controller = await addDatesInterval(rangeValue);

      expect(controller.serializedFiltersWith()).toBe('');

      rerenderDateRow();

      expect(rangeOperator()).toBeVisible();
      expect(controller.serializedFiltersWith()).toBe('');
    });

    it.each([
      ['2026-09-01 - ', '["2026-09-01",""]'],
      [' - 2026-09-30', '["","2026-09-30"]'],
    ])('still submits the one-sided range %j', async (rangeValue, serialized) => {
      const controller = await addDatesInterval('-');

      rangeInput().value = rangeValue;
      controller.sendForm();

      expect(controller.serializedFiltersWith()).toBe(`dates_interval <>d ${serialized}`);
    });

    it('releases the range row once both dates are set', async () => {
      const controller = await addDatesInterval('-');

      rangeInput().value = '2026-09-01 - 2026-09-30';
      controller.sendForm();
      expect(controller.serializedFiltersWith()).toBe('dates_interval <>d ["2026-09-01","2026-09-30"]');

      rerenderDateRow();

      expect(rangeOperator()).not.toBeVisible();
      expect(controller.serializedFiltersWith()).toBe('');
    });
  });

  describe('on the Meetings transport (JSON filters, stream morph of the subheader)', () => {
    function subheader(statusRow:StatusRow) {
      return form(statusRow)
        .replace('data-filter--filters-form-turbo-frame-request-value="backlogs_container"',
          'data-filter--filters-form-turbo-stream-request-value="true" data-filter--filters-form-output-format-value="json"');
    }

    function streamResponse(statusRow:StatusRow) {
      return `<turbo-stream action="update" method="morph" target="subheader">
        <template><span data-rendered></span>${subheader(statusRow)}</template>
      </turbo-stream>`;
    }

    let fetchSpy:ReturnType<typeof vi.fn>;

    beforeEach(() => {
      document.body.insertAdjacentHTML('beforeend', '<div id="global-loading-indicator" hidden></div>');
      fetchSpy = vi.fn((_url:string) => Promise.resolve(new Response(streamResponse(UNKNOWN_TO_SERVER))));
      vi.stubGlobal('fetch', fetchSpy);
    });

    afterEach(() => {
      vi.unstubAllGlobals();
      document.getElementById('global-loading-indicator')?.remove();
    });

    it('keeps the added row through the morphed response and never sends it', async () => {
      ctx = await setupStimulusTest({ controllers: { 'filter--filters-form': Controller } });
      await ctx.mount(`<div id="subheader">${subheader(UNKNOWN_TO_SERVER)}</div>`);
      const controller = ctx.getController<FiltersFormControllerType>('filter--filters-form');
      window.history.replaceState(window.history.state, '', `${window.location.pathname}?filters=[]`);

      addStatusFilter(controller);
      // Adding the empty row alone changes nothing the server would receive, so sendForm()
      // returns early; an unrelated (unowned) filter change forces the request.
      controller.currentFiltersValue = [{ title: { operator: '~', values: ['x'] } }];
      controller.sendForm();

      await vi.waitFor(() => expect(ctx.container.querySelector('[data-rendered]')).not.toBeNull());

      expect(fetchSpy).toHaveBeenCalledTimes(1);
      const filtersParam = new URL(String(fetchSpy.mock.calls[0][0]), window.location.origin).searchParams.get('filters');
      expect(filtersParam).toBe('[{"title":{"operator":"~","values":["x"]}}]');
      expect(filtersParam).not.toContain('status_id');
      expect(statusOperator()).toBeVisible();
      expect(statusOption()).toBeDisabled();
    });
  });
});
