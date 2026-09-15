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
import { vi, type Mock } from 'vitest';
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

const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const NEGOTIATED_ACCEPT = 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml';
const STREAM_HTML = '<turbo-stream action="append" target="stream-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': STREAM_CONTENT_TYPE } });
}

function htmlResponse():Response {
  return new Response('<p>Login</p>', { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}

describe('Filters form controller - live turbo stream requests', () => {
  let ctx:StimulusTestContext;
  let FiltersFormController:typeof FiltersFormControllerType;
  let fetchSpy:Mock;
  let replaceState:Mock;
  let target:HTMLElement;
  let loadingIndicator:HTMLElement;

  beforeAll(async () => {
    ({ default: FiltersFormController } = await import('./filters-form.controller'));
  });

  beforeEach(async () => {
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(streamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);
    replaceState = vi.fn();
    vi.spyOn(window.history, 'replaceState').mockImplementation(replaceState);

    target = document.createElement('div');
    target.id = 'stream-target';
    document.body.appendChild(target);

    loadingIndicator = document.createElement('div');
    loadingIndicator.id = 'global-loading-indicator';
    loadingIndicator.hidden = true;
    document.body.appendChild(loadingIndicator);

    ctx = await setupStimulusTest({
      controllers: { 'filter--filters-form': FiltersFormController },
    });
    await ctx.mount(`
      <div data-controller="filter--filters-form"
           data-filter--filters-form-turbo-stream-request-value="true"
           data-filter--filters-form-url-path-name-value="/projects">
        <button data-filter--filters-form-target="filterFormToggle">Filter</button>
        <span data-filter--filters-form-target="filterCount" hidden>0</span>
        <select data-filter--filters-form-target="addFilterSelect">
          <option value=""></option>
          <option value="assignee">Assignee</option>
        </select>
        ${ASSIGNEE_FILTER_ROW}
      </div>
    `);
    ctx.getController<FiltersFormControllerType>('filter--filters-form').addFilterByName('assignee');
    // Revealing the row submits the filter set (empty assignee value) once; every test starts after that settled.
    await waitFor(() => { if (!replaceState.mock.calls.length) throw new Error('waiting for initial replaceState'); });
    await waitFor(() => { if (target.querySelectorAll('.chunk').length !== 1) throw new Error('waiting for initial chunk'); });
    fetchSpy.mockClear();
    replaceState.mockClear();
    target.replaceChildren();
  });

  const flush = () => new Promise((resolve) => { setTimeout(resolve, 20); });

  afterEach(async () => {
    await flush();
    ctx.dispose();
    target.remove();
    loadingIndicator.remove();
    vi.restoreAllMocks();
  });

  const renderedChunks = () => target.querySelectorAll('.chunk').length;
  const lastCall = () => fetchSpy.mock.lastCall as [string, RequestInit & { headers:Headers }];

  function enterSimpleValue(value:string) {
    const valueInput = ctx.container.querySelector<HTMLInputElement>('[data-filter--filters-form-target="simpleValue"]')!;
    valueInput.value = value;
    valueInput.dispatchEvent(new Event('input', { bubbles: true }));
  }

  it('requests the filtered page as a stream and records the url', async () => {
    enterSimpleValue('john');

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    const [url, init] = lastCall();
    expect(url.split('?')[0]).toBe('/projects');
    expect(url).toMatch(/[?&]filters=/);
    expect(decodeURIComponent(url)).toContain('assignee');
    expect(init.method).toBe('GET');
    expect(init.headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
    expect(init.headers.has('X-CSRF-Token')).toBe(false);
    await waitFor(() => { expect(replaceState).toHaveBeenCalledOnce(); });
    expect(replaceState.mock.lastCall?.[2]).toMatch(/filters=/);
    expect(loadingIndicator.hidden).toBe(true);
  });

  it('shows the loading indicator until the request settles', async () => {
    let resolveFetch!:(response:Response) => void;
    fetchSpy.mockImplementationOnce(() => new Promise<Response>((resolve) => { resolveFetch = resolve; }));

    enterSimpleValue('john');

    await waitFor(() => { expect(fetchSpy).toHaveBeenCalledOnce(); });
    expect(loadingIndicator.hidden).toBe(false);

    resolveFetch(streamResponse());

    await waitFor(() => { expect(loadingIndicator.hidden).toBe(true); });
  });

  it('does not repeat a request for unchanged filters', async () => {
    enterSimpleValue('john');
    await waitFor(() => { expect(fetchSpy).toHaveBeenCalledOnce(); });

    ctx.getController<FiltersFormControllerType>('filter--filters-form').sendForm();

    expect(fetchSpy).toHaveBeenCalledOnce();
  });

  it.each([422, 500])('renders an HTTP %i stream once and still records the url', async (status) => {
    fetchSpy.mockResolvedValueOnce(streamResponse(status));

    enterSimpleValue('john');

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    await flush();
    expect(renderedChunks()).toBe(1);
    expect(replaceState).toHaveBeenCalledOnce();
    expect(loadingIndicator.hidden).toBe(true);
  });

  it('renders nothing for a non-stream response but still records the url', async () => {
    fetchSpy.mockResolvedValueOnce(htmlResponse());

    enterSimpleValue('john');

    await waitFor(() => { expect(replaceState).toHaveBeenCalledOnce(); });
    expect(renderedChunks()).toBe(0);
    expect(loadingIndicator.hidden).toBe(true);
  });

  it('hides the indicator and allows a retry when the request fails', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));

    enterSimpleValue('john');

    await waitFor(() => { expect(consoleError).toHaveBeenCalledOnce(); });
    expect(loadingIndicator.hidden).toBe(true);
    expect(replaceState).not.toHaveBeenCalled();

    enterSimpleValue('john');

    await waitFor(() => { expect(fetchSpy).toHaveBeenCalledTimes(2); });
  });
});
