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
import JiraConfigurationFormController from './jira-configuration-form.controller';

const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const NEGOTIATED_ACCEPT = 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml';
const STREAM_HTML = '<turbo-stream action="append" target="stream-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': STREAM_CONTENT_TYPE } });
}

function htmlResponse():Response {
  return new Response('<p>Login</p>', { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}

describe('Admin JIRA configuration form controller', () => {
  let ctx:StimulusTestContext;
  let fetchSpy:Mock;
  let target:HTMLElement;
  let csrfMeta:HTMLMetaElement;

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

    ctx = await setupStimulusTest({
      controllers: { 'admin--jira-configuration-form': JiraConfigurationFormController },
    });
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
  const lastCall = () => fetchSpy.mock.lastCall as [string, RequestInit & { headers:Headers, body:FormData }];

  async function mountForm({ id = '7', token = 'secret' } = {}) {
    const idAttribute = id ? `data-admin--jira-configuration-form-id-value="${id}"` : '';
    await ctx.mount(`
      <form data-controller="admin--jira-configuration-form"
            data-admin--jira-configuration-form-url-value="/admin/import/jira/test"
            ${idAttribute}>
        <input data-admin--jira-configuration-form-target="urlInput" value=" https://jira.example.com ">
        <input data-admin--jira-configuration-form-target="tokenInput" value="${token}">
        <button type="button" data-admin--jira-configuration-form-target="button"
                data-action="click->admin--jira-configuration-form#testConnection">Test</button>
        <button type="submit" data-admin--jira-configuration-form-target="button">Save</button>
        <div data-admin--jira-configuration-form-target="progressBanner" hidden>Testing</div>
      </form>
    `);

    const form = ctx.container.querySelector('form')!;
    return {
      test: form.querySelector<HTMLButtonElement>('button[type="button"]')!,
      buttons: Array.from(form.querySelectorAll('button')),
      banner: form.querySelector<HTMLElement>('[data-admin--jira-configuration-form-target="progressBanner"]')!,
    };
  }

  it('posts the trimmed url, token and id as form data', async () => {
    const { test } = await mountForm();

    test.click();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    const [url, init] = lastCall();
    expect(url).toBe('/admin/import/jira/test');
    expect(init.method).toBe('POST');
    expect(init.headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
    expect(init.headers.get('X-CSRF-Token')).toBe('token-123');
    expect(init.body).toBeInstanceOf(FormData);
    expect(init.body.get('url')).toBe('https://jira.example.com');
    expect(init.body.get('personal_access_token')).toBe('secret');
    expect(init.body.get('id')).toBe('7');
  });

  it('omits a blank token and a missing id', async () => {
    const { test } = await mountForm({ id: '', token: '' });

    test.click();

    await waitFor(() => { expect(fetchSpy).toHaveBeenCalledOnce(); });
    const [, init] = lastCall();
    expect(init.body.has('personal_access_token')).toBe(false);
    expect(init.body.has('id')).toBe(false);
  });

  it('disables the buttons and shows the banner until the request settles', async () => {
    let resolveFetch!:(response:Response) => void;
    fetchSpy.mockImplementationOnce(() => new Promise<Response>((resolve) => { resolveFetch = resolve; }));
    const { test, buttons, banner } = await mountForm();

    test.click();

    await waitFor(() => { expect(fetchSpy).toHaveBeenCalledOnce(); });
    expect(buttons.every((button) => button.disabled)).toBe(true);
    expect(banner.hidden).toBe(false);

    resolveFetch(streamResponse());

    await waitFor(() => { expect(banner.hidden).toBe(true); });
    expect(buttons.every((button) => !button.disabled)).toBe(true);
  });

  it.each([422, 500])('renders an HTTP %i stream exactly once', async (status) => {
    fetchSpy.mockResolvedValueOnce(streamResponse(status));
    const { test, banner } = await mountForm();

    test.click();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    await flush();
    expect(renderedChunks()).toBe(1);
    expect(banner.hidden).toBe(true);
  });

  it('renders nothing for a non-stream response and restores the form', async () => {
    fetchSpy.mockResolvedValueOnce(htmlResponse());
    const { test, buttons, banner } = await mountForm();

    test.click();

    await waitFor(() => { expect(banner.hidden).toBe(true); });
    expect(renderedChunks()).toBe(0);
    expect(buttons.every((button) => !button.disabled)).toBe(true);
  });

  it('logs and restores the form when the request fails', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));
    const { test, buttons, banner } = await mountForm();

    test.click();

    await waitFor(() => { expect(consoleError).toHaveBeenCalledOnce(); });
    expect(banner.hidden).toBe(true);
    expect(buttons.every((button) => !button.disabled)).toBe(true);
  });
});
