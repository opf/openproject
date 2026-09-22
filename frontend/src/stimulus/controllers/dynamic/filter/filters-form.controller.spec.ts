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
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type FiltersFormControllerType from './filters-form.controller';

const ASSIGNEE_FILTER_ROW = `
  <div data-filter-name="assignee" data-filter-type="text" hidden data-filter--filters-form-target="filter">
    <select data-filter-name="assignee" data-filter--filters-form-target="operator">
      <option value="=">is</option>
      <option value="!*" data-no-value>is not set</option>
    </select>
    <div data-filter-name="assignee" data-filter--filters-form-target="filterValueContainer">
      <input data-filter-name="assignee" data-filter--filters-form-target="simpleValue">
    </div>
  </div>
`;

describe('Filters form controller - filter count badge', () => {
  let ctx:StimulusTestContext;
  let FiltersFormController:typeof FiltersFormControllerType;

  beforeAll(async () => {
    ({ default: FiltersFormController } = await import('./filters-form.controller'));
  });

  afterEach(() => {
    ctx.dispose();
  });

  async function mountForm(filterRow:string) {
    ctx = await setupStimulusTest({
      controllers: { 'filter--filters-form': FiltersFormController },
    });

    await ctx.mount(`
      <div data-controller="filter--filters-form">
        <button data-filter--filters-form-target="filterFormToggle">Filter</button>
        <span data-filter--filters-form-target="filterCount" hidden>0</span>
        <span data-filter--filters-form-target="filterCount" hidden>0</span>
        <input type="hidden" data-filter--filters-form-target="filtersInput">
        <select data-filter--filters-form-target="addFilterSelect">
          <option value=""></option>
          <option value="assignee">Assignee</option>
        </select>
        ${filterRow}
      </div>
    `);

    const controller = ctx.getController<FiltersFormControllerType>('filter--filters-form');
    const counters = Array.from(ctx.container.querySelectorAll<HTMLElement>('[data-filter--filters-form-target="filterCount"]'));

    return { controller, counters };
  }

  function enterSimpleValue(value:string) {
    const valueInput = ctx.container.querySelector<HTMLInputElement>('[data-filter--filters-form-target="simpleValue"]')!;
    valueInput.value = value;
    valueInput.dispatchEvent(new Event('input', { bubbles: true }));
  }

  it('leaves the count unchanged when a filter is added with no value yet', async () => {
    const { controller, counters } = await mountForm(ASSIGNEE_FILTER_ROW);

    controller.addFilterByName('assignee');
    await ctx.nextFrame();

    counters.forEach((counter) => {
      expect(counter.textContent).toBe('0');
      expect(counter.hidden).toBe(true);
    });
  });

  it('increments the count once a value is entered', async () => {
    const { controller, counters } = await mountForm(ASSIGNEE_FILTER_ROW);

    controller.addFilterByName('assignee');
    await ctx.nextFrame();
    enterSimpleValue('john');

    // The counter update is debounced together with the network request, so
    // it lands asynchronously rather than right after the input event.
    await waitFor(() => {
      counters.forEach((counter) => {
        expect(counter.textContent).toBe('1');
        expect(counter.hidden).toBe(false);
      });
    });
  });

  it('decrements the count when an active filter is removed', async () => {
    const { controller, counters } = await mountForm(ASSIGNEE_FILTER_ROW);

    controller.addFilterByName('assignee');
    enterSimpleValue('john');

    // The counter update is debounced together with the network request, so
    // it lands asynchronously rather than right after the input event.
    await waitFor(() => {
      counters.forEach((counter) => {
        expect(counter.textContent).toBe('1');
        expect(counter.hidden).toBe(false);
      });
    });

    controller.removeFilter({ params: { filterName: 'assignee' } });
    await ctx.nextFrame();

    // Not just re-hidden -- the text itself must be updated back to 0 too,
    // rather than staying stale at the last visible count while hidden.
    counters.forEach((counter) => {
      expect(counter.textContent).toBe('0');
      expect(counter.hidden).toBe(true);
    });
  });

  it('counts a data-no-value operator immediately, without a value', async () => {
    const { controller, counters } = await mountForm(ASSIGNEE_FILTER_ROW);
    const operatorSelect = ctx.container.querySelector<HTMLSelectElement>('[data-filter--filters-form-target="operator"]')!;
    operatorSelect.value = '!*';

    controller.addFilterByName('assignee');
    await ctx.nextFrame();

    counters.forEach((counter) => {
      expect(counter.textContent).toBe('1');
      expect(counter.hidden).toBe(false);
    });
  });
});

describe('Filters form controller - rows added without a value', () => {
  let ctx:StimulusTestContext;
  let FiltersFormController:typeof FiltersFormControllerType;

  beforeAll(async () => {
    ({ default: FiltersFormController } = await import('./filters-form.controller'));
  });

  afterEach(() => {
    ctx.dispose();
  });

  async function mountForm() {
    ctx = await setupStimulusTest({
      controllers: { 'filter--filters-form': FiltersFormController },
    });

    await ctx.mount(`
      <div data-controller="filter--filters-form">
        <select data-filter--filters-form-target="addFilterSelect">
          <option value=""></option>
          <option value="assignee">Assignee</option>
        </select>
        ${ASSIGNEE_FILTER_ROW}
      </div>
    `);

    return ctx.getController<FiltersFormControllerType>('filter--filters-form');
  }

  function row() {
    return ctx.container.querySelector<HTMLElement>('[data-filter--filters-form-target="filter"]')!;
  }

  function addFilterOption() {
    return ctx.container.querySelector<HTMLOptionElement>('option[value="assignee"]')!;
  }

  it('shows the row again after a re-render hid it', async () => {
    const controller = await mountForm();
    controller.addFilterByName('assignee');

    // What the server sends back: the query does not hold the filter, so the row is hidden
    // and its entry in the add-filter select is selectable again.
    row().setAttribute('hidden', '');
    addFilterOption().removeAttribute('disabled');

    controller.restorePendingFilters();

    expect(row().hasAttribute('hidden')).toBe(false);
    expect(addFilterOption().hasAttribute('disabled')).toBe(true);
  });

  it('leaves a row the user removed hidden', async () => {
    const controller = await mountForm();
    controller.addFilterByName('assignee');
    controller.removeFilter({ params: { filterName: 'assignee' } });

    controller.restorePendingFilters();

    expect(row().hasAttribute('hidden')).toBe(true);
  });

  it('stops tracking a row once the server renders it itself', async () => {
    const controller = await mountForm();
    controller.addFilterByName('assignee');

    // A re-render that leaves the row visible means the query holds the filter now, so the
    // row stops being this controller's business and a later re-render decides on its own.
    controller.restorePendingFilters();
    row().setAttribute('hidden', '');
    controller.restorePendingFilters();

    expect(row().hasAttribute('hidden')).toBe(true);
  });
});
