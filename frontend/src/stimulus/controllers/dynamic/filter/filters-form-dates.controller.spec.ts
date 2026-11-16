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

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type FiltersFormControllerType from './filters-form.controller';

const dateValueFields = { '=d': 'singleDay', '>d': 'singleDay', '<>d': 'dateRange' };
const datetimeValueFields = { '=d': 'singleDay', '>d': 'singleDatetime', '<>d': 'datetimeRange' };

function dateFilterRow(type:string, operator:string, values:Record<string, string>) {
  const valueFields = type === 'date' ? dateValueFields : datetimeValueFields;
  const inputs = Object.entries(values)
    .map(([target, value]) => `<input data-filter-name="created_at" data-filter--filters-form-target="${target}" value="${value}">`)
    .join('');

  return `
    <div data-filter-name="created_at" data-filter-type="${type}" data-filter--filters-form-target="filter">
      <select data-filter-name="created_at" data-filter--filters-form-target="operator">
        <option value="${operator}" selected>${operator}</option>
      </select>
      <div data-filter-name="created_at" data-filter--filters-form-target="filterValueContainer"
           data-value-fields='${JSON.stringify(valueFields)}'>
        ${inputs}
      </div>
    </div>
  `;
}

describe('Filters form controller - date filter values', () => {
  let ctx:StimulusTestContext;
  let FiltersFormController:typeof FiltersFormControllerType;
  let currentUserMeta:HTMLMetaElement;

  beforeAll(async () => {
    ({ default: FiltersFormController } = await import('./filters-form.controller'));
  });

  beforeEach(() => {
    currentUserMeta = document.createElement('meta');
    currentUserMeta.name = 'current_user';
    currentUserMeta.dataset.timeZone = 'Europe/Berlin';
    document.head.appendChild(currentUserMeta);
  });

  afterEach(() => {
    ctx.dispose();
    currentUserMeta.remove();
  });

  async function submittedFilters(filterRow:string):Promise<unknown> {
    ctx = await setupStimulusTest({
      controllers: { 'filter--filters-form': FiltersFormController },
    });

    await ctx.mount(`
      <div data-controller="filter--filters-form" data-filter--filters-form-output-format-value="json">
        <input type="hidden" data-filter--filters-form-target="filtersInput">
        ${filterRow}
      </div>
    `);

    ctx.getController<FiltersFormControllerType>('filter--filters-form').sendForm();

    const filtersInput = ctx.container.querySelector<HTMLInputElement>('[data-filter--filters-form-target="filtersInput"]')!;
    return JSON.parse(filtersInput.value) as unknown;
  }

  it('sends both datetimes of a datetime range unchanged', async () => {
    const filters = await submittedFilters(dateFilterRow('datetime', '<>d', {
      datetimeFrom: '2026-01-01T08:30:00Z',
      datetimeTo: '2026-10-30T17:00:00Z',
    }));

    expect(filters).toEqual([
      { created_at: { operator: '<>d', values: ['2026-01-01T08:30:00Z', '2026-10-30T17:00:00Z'] } },
    ]);
  });

  it('keeps an open end of a datetime range empty', async () => {
    const filters = await submittedFilters(dateFilterRow('datetime', '<>d', {
      datetimeFrom: '2026-01-01T08:30:00Z',
      datetimeTo: '',
    }));

    expect(filters).toEqual([
      { created_at: { operator: '<>d', values: ['2026-01-01T08:30:00Z', ''] } },
    ]);
  });

  it('sends the start of the day for an on-date datetime filter', async () => {
    const filters = await submittedFilters(dateFilterRow('datetime_past', '=d', { singleDay: '2026-07-01' }));

    expect(filters).toEqual([
      { created_at: { operator: '=d', values: ['2026-06-30T22:00:00Z'] } },
    ]);
  });

  it('sends the datetime unchanged for a greater or equal datetime filter', async () => {
    const filters = await submittedFilters(dateFilterRow('datetime_past', '>d', { singleDatetime: '2026-07-01T08:30:00Z' }));

    expect(filters).toEqual([
      { created_at: { operator: '>d', values: ['2026-07-01T08:30:00Z'] } },
    ]);
  });

  it('sends a plain date for a greater or equal date filter', async () => {
    const filters = await submittedFilters(dateFilterRow('date', '>d', { singleDay: '2026-07-01' }));

    expect(filters).toEqual([
      { created_at: { operator: '>d', values: ['2026-07-01'] } },
    ]);
  });

  it('sends plain dates for a date filter', async () => {
    const filters = await submittedFilters(dateFilterRow('date', '<>d', { dateRange: '2026-01-01 - 2026-10-30' }));

    expect(filters).toEqual([
      { created_at: { operator: '<>d', values: ['2026-01-01', '2026-10-30'] } },
    ]);
  });
});
