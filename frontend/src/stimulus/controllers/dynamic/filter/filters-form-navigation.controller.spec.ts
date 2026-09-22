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

describe('Filters form navigation', () => {
  const framePath = '/projects/demo/backlogs/backlog';

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
    visit.mockRestore();
    ctx.dispose();
    window.history.replaceState(window.history.state, '', originalUrl);
  });

  const STATUS_LIST_ROW = `
    <select data-filter--filters-form-target="addFilterSelect">
      <option value=""></option>
      <option value="status_id">Status</option>
    </select>
    <div data-filter-name="status_id" data-filter-type="list" hidden data-filter--filters-form-target="filter">
      <select data-filter-name="status_id" data-filter--filters-form-target="operator">
        <option value="=">is (OR)</option>
        <option value="!*" data-no-value>is not set</option>
      </select>
      <div data-filter-name="status_id" data-filter-autocomplete="true"
        data-filter--filters-form-target="filterValueContainer">
        <input type="hidden" name="value" value="">
      </div>
    </div>
  `;

  async function mount(resetParams?:string[], innerHtml = '') {
    const data = resetParams
      ? `data-filter--filters-form-reset-params-value='${JSON.stringify(resetParams)}'`
      : '';
    ctx = await setupStimulusTest({ controllers: { 'filter--filters-form': Controller } });
    await ctx.mount(`<div data-controller="filter--filters-form"
      data-filter--filters-form-turbo-frame-request-value="backlogs_container"
      data-filter--filters-form-url-path-name-value="${framePath}" ${data}>${innerHtml}</div>`);
    return ctx.getController<FiltersFormControllerType>('filter--filters-form');
  }

  function selectStatus(id:string) {
    ctx.container.querySelector<HTMLInputElement>('input[name="value"]')!.value = id;
  }

  function setUrl(filters?:string) {
    const params = new URLSearchParams('all=true&page=3&bucket_ids[]=inbox&bucket_ids[]=7&sprint_ids[]=8&sortBy=position');
    if (filters !== undefined) params.set('filters', filters);
    window.history.replaceState(window.history.state, '', `${window.location.pathname}?${params}`);
  }

  function visitedUrl():URL {
    expect(visit).toHaveBeenCalledTimes(1);
    expect(visit.mock.calls[0][1]).toEqual({ frame: 'backlogs_container', action: 'advance' });
    return new URL(String(visit.mock.calls[0][0]), window.location.origin);
  }

  const changes:FiltersFormControllerType['currentFiltersValue'][] = [
    [{ subject: { operator: '~', values: ['new'] } }],
    [{ subject: { operator: '!~', values: ['old'] } }],
    [{ status_id: { operator: '=', values: ['2'] } }],
    [{ status_id: { operator: '!', values: ['1'] } }],
    [],
  ];

  it.each(changes.map((filters) => ({ filters })))('resets expansion for changed filters: $filters', async ({ filters }) => {
    setUrl('subject ~ "old"');
    const controller = await mount(['page', 'all']);
    controller.currentFiltersValue = filters;
    controller.sendForm();

    const url = visitedUrl();
    expect(url.searchParams.has('all')).toBe(false);
    expect(url.searchParams.has('page')).toBe(false);
    expect(url.searchParams.getAll('bucket_ids[]')).toEqual(['inbox', '7']);
    expect(url.searchParams.getAll('sprint_ids[]')).toEqual(['8']);
    expect(url.searchParams.get('sortBy')).toBe('position');
    expect(url.pathname).toBe(framePath);
    expect(url.searchParams.get('filters') ?? '').toBe(controller.serializedFiltersWith());
  });

  it('keeps all for consumers using the default reset list', async () => {
    setUrl('subject ~ "old"');
    const controller = await mount();
    controller.sendForm();

    const url = visitedUrl();
    expect(url.searchParams.get('all')).toBe('true');
    expect(url.searchParams.has('page')).toBe(false);
  });

  it('resets expansion when adding the first effective filter', async () => {
    setUrl();
    const controller = await mount(['page', 'all']);
    controller.currentFiltersValue = [{ subject: { operator: '~', values: ['new'] } }];
    controller.sendForm();

    const url = visitedUrl();
    expect(url.searchParams.has('all')).toBe(false);
    expect(url.searchParams.get('filters')).toBe('subject ~ "new"');
  });

  it('keeps expansion until an added list filter receives a value', async () => {
    setUrl();
    const controller = await mount(['page', 'all'], STATUS_LIST_ROW);

    // The row has to reach the server, or the next re-render renders it hidden again. It
    // selects nothing yet, so the expansion survives.
    controller.addFilterByName('status_id');

    const added = visitedUrl();
    expect(added.searchParams.get('all')).toBe('true');
    expect(added.searchParams.get('filters')).toBe('status_id = ""');

    visit.mockClear();
    selectStatus('2');
    controller.autocompleteSendForm();

    const url = visitedUrl();
    expect(url.searchParams.has('all')).toBe(false);
    expect(url.searchParams.get('filters')).toBe('status_id = "2"');
  });

  it('keeps an added row alongside the filters already applied', async () => {
    setUrl('subject ~ "old"');
    const controller = await mount(['page', 'all'], STATUS_LIST_ROW);
    controller.currentFiltersValue = [{ subject: { operator: '~', values: ['old'] } }];

    controller.addFilterByName('status_id');

    const url = visitedUrl();
    expect(url.searchParams.get('filters')).toBe('subject ~ "old"&status_id = ""');
    expect(url.searchParams.get('all')).toBe('true');
    expect(url.searchParams.get('page')).toBe('3');
  });

  it('serializes several selected list values', async () => {
    setUrl();
    const controller = await mount(['page', 'all'], STATUS_LIST_ROW);

    controller.addFilterByName('status_id');
    visit.mockClear();
    selectStatus('2,5');
    controller.autocompleteSendForm();

    expect(visitedUrl().searchParams.get('filters')).toBe('status_id = ["2","5"]');
  });

  it('resets expansion for a value-less operator on a list filter', async () => {
    setUrl();
    const controller = await mount(['page', 'all'], STATUS_LIST_ROW);
    ctx.container.querySelector<HTMLSelectElement>('[data-filter--filters-form-target="operator"]')!.value = '!*';

    controller.addFilterByName('status_id');

    const url = visitedUrl();
    expect(url.searchParams.has('all')).toBe(false);
    expect(url.searchParams.get('filters')).toBe('status_id !* ""');
  });

  it.each([undefined, '', 'subject ~ "old"'])('does not navigate for unchanged filters: %s', async (filters) => {
    setUrl(filters);
    const controller = await mount(['page', 'all']);
    controller.currentFiltersValue = filters ? [{ subject: { operator: '~', values: ['old'] } }] : [];
    controller.sendForm();

    expect(visit).not.toHaveBeenCalled();
  });
});
