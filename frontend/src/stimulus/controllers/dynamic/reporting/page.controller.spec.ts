/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */
/* eslint-disable @typescript-eslint/no-explicit-any */

import PageController from './page.controller';

describe('Reporting PageController serialization', () => {
  let controller:PageController & Record<string, any>;
  let privateController:{
    syncFilterValues:(formData:FormData, field:string) => void;
    syncActiveFilters:(formData:FormData) => void;
  };
  let fixturesElement:HTMLElement;

  beforeEach(() => {
    controller = Object.create(PageController.prototype) as PageController & Record<string, any>;
    privateController = controller as unknown as {
      syncFilterValues:(formData:FormData, field:string) => void;
      syncActiveFilters:(formData:FormData) => void;
    };
    fixturesElement = document.createElement('div');
    document.body.appendChild(fixturesElement);
  });

  afterEach(() => {
    fixturesElement.remove();
  });

  function formDataValues(formData:FormData, key:string) {
    return formData.getAll(key).map(String);
  }

  it('serializes non-empty materialized inputs directly', () => {
    fixturesElement.innerHTML = `
      <li id="filter_user_id">
        <input type="hidden" name="values[user_id][]" value="me">
      </li>
    `;

    const formData = new FormData();

    privateController.syncFilterValues(formData, 'user_id');

    expect(formDataValues(formData, 'values[user_id][]')).toEqual(['me']);
  });

  it('serializes scalar filter inputs with their original name', () => {
    fixturesElement.innerHTML = `
      <li id="filter_subject">
        <input type="text" name="values[subject]" value="abc">
      </li>
    `;

    const formData = new FormData();

    privateController.syncFilterValues(formData, 'subject');

    expect(formDataValues(formData, 'values[subject]')).toEqual(['abc']);
    expect(formDataValues(formData, 'values[subject][]')).toEqual([]);
  });

  it('falls back to the date picker dataset when the input is still empty', () => {
    fixturesElement.innerHTML = `
      <li id="filter_spent_on">
        <opce-basic-single-date-picker
          data-name='"values[spent_on][]"'
          data-value='"2026-03-07"'>
          <input type="text" name="values[spent_on][]" value="">
        </opce-basic-single-date-picker>
      </li>
    `;

    const formData = new FormData();

    privateController.syncFilterValues(formData, 'spent_on');

    expect(formDataValues(formData, 'values[spent_on][]')).toEqual(['2026-03-07']);
  });

  it('falls back to autocompleter dataset values with numeric and string ids', () => {
    fixturesElement.innerHTML = `
      <li id="filter_work_package_id">
        <opce-autocompleter
          data-input-name='"values[work_package_id]"'
          data-model='[{"id":42,"name":"WP"},{"id":"77","name":"Saved"}]'>
        </opce-autocompleter>
      </li>
    `;

    const formData = new FormData();

    privateController.syncFilterValues(formData, 'work_package_id');

    expect(formDataValues(formData, 'values[work_package_id][]')).toEqual(['42', '77']);
  });

  it('ignores missing filter elements when syncing active filters', () => {
    vi.spyOn(controller, 'visibleFilters').mockReturnValue(['missing']);

    const formData = new FormData();

    expect(() => privateController.syncActiveFilters(formData)).not.toThrow();
    expect(formDataValues(formData, 'fields[]')).toEqual(['missing']);
    expect(formDataValues(formData, 'values[missing][]')).toEqual([]);
  });

  it('skips filters with required operators when no value is present', () => {
    fixturesElement.innerHTML = `
      <select name="operators[updated_on]">
        <option value=">=d" data-arity="1" selected>>=d</option>
      </select>
      <li id="filter_updated_on">
        <input type="text" name="values[updated_on][]" value="">
      </li>
    `;

    vi.spyOn(controller, 'visibleFilters').mockReturnValue(['updated_on']);

    const formData = new FormData();

    privateController.syncActiveFilters(formData);

    expect(formDataValues(formData, 'fields[]')).toEqual([]);
    expect(formDataValues(formData, 'operators[updated_on]')).toEqual([]);
    expect(formDataValues(formData, 'values[updated_on][]')).toEqual([]);
  });

  it('falls back to the filter data attribute when the remove input is blank', () => {
    fixturesElement.innerHTML = `
      <li data-filter-name="subject">
        <div id="rm_box_subject">
          <input type="hidden" name="fields[]" value="">
        </div>
      </li>
    `;

    const removeBox = fixturesElement.querySelector<HTMLElement>('#rm_box_subject')!;
    const removedFilters:string[] = [];
    Object.assign(controller, {
      filters: {
        remove_filter(filter:string) {
          removedFilters.push(filter);
        },
      },
    });

    controller.removeFilter({
      preventDefault: () => undefined,
      currentTarget: removeBox,
    } as unknown as MouseEvent);

    expect(removedFilters).toEqual(['subject']);
  });
});
