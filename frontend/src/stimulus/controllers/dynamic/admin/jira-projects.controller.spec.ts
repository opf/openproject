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
import JiraProjectsController from './jira-projects.controller';

const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const NEGOTIATED_ACCEPT = 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml';
const STREAM_HTML = '<turbo-stream action="append" target="stream-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': STREAM_CONTENT_TYPE } });
}

function htmlResponse():Response {
  return new Response('<p>Login</p>', { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}

describe('Admin JIRA projects controller', () => {
  let ctx:StimulusTestContext;
  let fetchSpy:Mock;
  let target:HTMLElement;
  let csrfMeta:HTMLMetaElement;
  let checkbox:HTMLInputElement;
  let checkAll:HTMLAnchorElement;
  let filter:HTMLInputElement;
  let submitButton:HTMLElement;
  let spinnerButton:HTMLElement;

  beforeEach(async () => {
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(streamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    target = document.createElement('div');
    target.id = 'stream-target';
    document.body.appendChild(target);

    csrfMeta = document.createElement('meta');
    csrfMeta.name = 'csrf-token';
    csrfMeta.content = 'token-123';
    document.head.appendChild(csrfMeta);

    ctx = await setupStimulusTest({ controllers: { 'admin--jira-projects': JiraProjectsController } });
    await ctx.mount(`
      <div data-controller="admin--jira-projects"
           data-admin--jira-projects-toggle-url-value="/admin/import/jira/1/run/2/select_projects/toggle?project_id=PROJECT_ID"
           data-admin--jira-projects-filter-url-value="/admin/import/jira/1/run/2/select_projects/filter"
           data-admin--jira-projects-debounce-value="0">
        <input type="checkbox" value="10001" data-action="change->admin--jira-projects#toggleProject">
        <a href="/admin/import/jira/1/run/2/select_projects/check_all" data-action="click->admin--jira-projects#checkAll">All</a>
        <input type="text" data-action="input->admin--jira-projects#filterProjects">
        <button type="button" data-admin--jira-projects-target="submitButton">Save</button>
        <button type="button" data-admin--jira-projects-target="spinnerButton" hidden>Working</button>
      </div>
    `);

    checkbox = ctx.container.querySelector('input[type="checkbox"]')!;
    checkAll = ctx.container.querySelector('a')!;
    filter = ctx.container.querySelector('input[type="text"]')!;
    submitButton = ctx.container.querySelector('[data-admin--jira-projects-target="submitButton"]')!;
    spinnerButton = ctx.container.querySelector('[data-admin--jira-projects-target="spinnerButton"]')!;
  });

  const flush = () => new Promise((resolve) => { setTimeout(resolve, 20); });

  afterEach(async () => {
    await flush();
    ctx.dispose();
    target.remove();
    csrfMeta.remove();
    vi.restoreAllMocks();
  });

  const renderedChunks = () => target.querySelectorAll('.chunk').length;
  const callAt = (index:number) => fetchSpy.mock.calls[index] as [string, RequestInit & { headers:Headers, body:FormData }];

  it('toggles a project with a stream GET and renders the counter', async () => {
    checkbox.click();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    const [url, init] = callAt(0);
    expect(url).toBe('/admin/import/jira/1/run/2/select_projects/toggle?project_id=10001');
    expect(init.method).toBe('GET');
    expect(init.headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
    expect(init.headers.has('X-CSRF-Token')).toBe(false);
  });

  it('requests the bulk action from the link href without navigating', async () => {
    const event = new MouseEvent('click', { bubbles: true, cancelable: true });

    checkAll.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    expect(callAt(0)[0]).toBe(checkAll.href);
    expect(callAt(0)[1].method).toBe('GET');
  });

  it('posts the filter as form data with the CSRF token', async () => {
    filter.value = 'crm';
    filter.dispatchEvent(new Event('input', { bubbles: true }));

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    const [url, init] = callAt(0);
    expect(url).toBe('/admin/import/jira/1/run/2/select_projects/filter');
    expect(init.method).toBe('POST');
    expect(init.headers.get('X-CSRF-Token')).toBe('token-123');
    expect(init.headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
    expect(init.body).toBeInstanceOf(FormData);
    expect(init.body.get('filter')).toBe('crm');
  });

  it('sends queued requests one at a time and toggles the spinner meanwhile', async () => {
    const resolvers:((response:Response) => void)[] = [];
    fetchSpy.mockImplementation(() => new Promise<Response>((resolve) => { resolvers.push(resolve); }));

    checkbox.click();
    checkbox.click();

    await waitFor(() => { expect(fetchSpy).toHaveBeenCalledOnce(); });
    expect(submitButton.hidden).toBe(true);
    expect(spinnerButton.hidden).toBe(false);

    resolvers[0](streamResponse());

    await waitFor(() => { expect(fetchSpy).toHaveBeenCalledTimes(2); });
    expect(spinnerButton.hidden).toBe(false);

    resolvers[1](streamResponse());

    await waitFor(() => { expect(spinnerButton.hidden).toBe(true); });
    expect(submitButton.hidden).toBe(false);
    await waitFor(() => { expect(renderedChunks()).toBe(2); });
  });

  it.each([422, 500])('renders an HTTP %i stream exactly once', async (status) => {
    fetchSpy.mockResolvedValueOnce(streamResponse(status));

    checkbox.click();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    await flush();
    expect(renderedChunks()).toBe(1);
    expect(spinnerButton.hidden).toBe(true);
  });

  it('renders nothing for a non-stream response', async () => {
    fetchSpy.mockResolvedValueOnce(htmlResponse());

    checkbox.click();

    await waitFor(() => { expect(spinnerButton.hidden).toBe(true); });
    expect(renderedChunks()).toBe(0);
  });

  it('warns when a request fails', async () => {
    const consoleWarn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);
    fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));

    checkbox.click();

    await waitFor(() => { expect(consoleWarn).toHaveBeenCalledOnce(); });
    expect(renderedChunks()).toBe(0);
  });
});
