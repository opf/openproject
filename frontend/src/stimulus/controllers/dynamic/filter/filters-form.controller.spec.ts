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

    counters.forEach((counter) => {
      expect(counter.textContent).toBe('1');
      expect(counter.hidden).toBe(false);
    });
  });

  it('decrements the count when an active filter is removed', async () => {
    const { controller, counters } = await mountForm(ASSIGNEE_FILTER_ROW);

    controller.addFilterByName('assignee');
    enterSimpleValue('john');

    counters.forEach((counter) => {
      expect(counter.textContent).toBe('1');
      expect(counter.hidden).toBe(false);
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
