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

import * as Turbo from '@hotwired/turbo';
import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type FiltersFormControllerType from './filters-form.controller';

const STATUS_ROW_RESPONSE = `
  <turbo-frame id="filter_component">
    <form>
      <div class="FormControl-spacingWrapper">
        <div data-filter-name="status_id" data-filter-type="list" hidden data-filter--filters-form-target="filter">
          <select aria-label="Status operator" data-filter-name="status_id" data-filter--filters-form-target="operator">
            <option value="=">is (OR)</option>
          </select>
          <div data-filter-name="status_id" data-filter-autocomplete="true"
            data-filter--filters-form-target="filterValueContainer">
            <input type="hidden" name="value" value="">
          </div>
        </div>
        <div class="FormControl-spacingWrapper">
          <select data-filter--filters-form-target="addFilterSelect"></select>
        </div>
      </div>
    </form>
  </turbo-frame>
`;

describe('Filters form lazy rows', () => {
  let ctx:StimulusTestContext;
  let Controller:typeof FiltersFormControllerType;
  let fetchSpy:Mock;
  let resolveResponse!:(response:Response) => void;
  let rejectResponse!:(error:Error) => void;

  beforeAll(async () => {
    ({ default: Controller } = await import('./filters-form.controller'));
  });

  beforeEach(async () => {
    fetchSpy = vi.fn().mockImplementation((_url:URL, { signal }:RequestInit) => new Promise<Response>((resolve, reject) => {
      resolveResponse = resolve;
      rejectResponse = reject;
      signal?.addEventListener('abort', () => reject(signal.reason as Error));
    }));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    ctx = await setupStimulusTest({ controllers: { 'filter--filters-form': Controller } });
    await ctx.mount(`
      <div data-controller="filter--filters-form">
        <div class="FormControl-spacingWrapper">
          <div class="FormControl-spacingWrapper">
            <select aria-label="Add filter" data-filter--filters-form-target="addFilterSelect"
              data-rows-url="/projects/filters?filters=%5B%5D">
              <option value=""></option>
              <option value="status_id">Status</option>
            </select>
          </div>
        </div>
      </div>
    `);
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
  });

  const controller = () => ctx.getController<FiltersFormControllerType>('filter--filters-form');
  const host = () => ctx.container.querySelector<HTMLElement>('[data-controller]')!;
  const statusOption = () => ctx.screen.getByRole<HTMLOptionElement>('option', { name: 'Status', hidden: true });
  const statusRow = () => ctx.screen.queryByRole('combobox', { name: 'Status operator', hidden: true })
    ?.closest<HTMLElement>('[data-filter--filters-form-target="filter"]');
  const requestUrl = () => (fetchSpy.mock.calls[0] as [URL, RequestInit])[0];
  const requestSignal = () => (fetchSpy.mock.calls[0] as [URL, RequestInit])[1].signal!;

  async function addStatusFilterPending() {
    const adding = controller().addFilterByName('status_id');
    await waitFor(() => expect(fetchSpy).toHaveBeenCalledOnce());
    return { adding };
  }

  it('loads the row of a filter that is not on the page and shows it', async () => {
    const { adding } = await addStatusFilterPending();
    expect(statusOption().disabled).toBe(true);

    resolveResponse(new Response(STATUS_ROW_RESPONSE));
    await adding;

    expect(requestUrl().pathname).toBe('/projects/filters');
    expect(requestUrl().searchParams.get('filters')).toBe('[]');
    expect(requestUrl().searchParams.get('filter_row')).toBe('status_id');
    expect(statusRow()).toBeVisible();
    expect(statusOption().disabled).toBe(true);
  });

  it('enables the option again when the request fails', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    const { adding } = await addStatusFilterPending();

    rejectResponse(new TypeError('Failed to fetch'));
    await adding;

    expect(statusRow()).toBeUndefined();
    expect(statusOption().disabled).toBe(false);
    expect(consoleError).toHaveBeenCalled();
  });

  it('enables the option again after an error response', async () => {
    const { adding } = await addStatusFilterPending();

    resolveResponse(new Response('', { status: 500 }));
    await adding;

    expect(statusRow()).toBeUndefined();
    expect(statusOption().disabled).toBe(false);
  });

  it('caches the page with the option enabled while the row is still loading', async () => {
    const { adding } = await addStatusFilterPending();

    document.dispatchEvent(new CustomEvent('turbo:before-cache'));
    const { element: cached } = Turbo.PageSnapshot.fromElement(host()).clone() as unknown as { element:HTMLElement };
    await adding;

    expect(requestSignal().aborted).toBe(true);
    expect(statusRow()).toBeUndefined();
    expect(cached.querySelector<HTMLOptionElement>('option[value="status_id"]')!.disabled).toBe(false);
  });

  it('aborts the row request when the form disconnects', async () => {
    const { adding } = await addStatusFilterPending();

    host().remove();
    await adding;

    expect(requestSignal().aborted).toBe(true);
  });
});
