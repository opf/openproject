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
import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import AsyncDialogController from './async-dialog.controller';

const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const STREAM_HTML = '<turbo-stream action="append" target="dialog-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': STREAM_CONTENT_TYPE } });
}

describe('AsyncDialogController', () => {
  const progressBar = (Turbo.session.adapter as Turbo.BrowserAdapter).progressBar;
  let ctx:StimulusTestContext;
  let fetchSpy:Mock;
  let hideSpy:ReturnType<typeof vi.spyOn>;
  let target:HTMLElement;

  beforeEach(async () => {
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(streamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);
    vi.spyOn(progressBar, 'setValue').mockImplementation(() => undefined);
    vi.spyOn(progressBar, 'show').mockImplementation(() => undefined);
    hideSpy = vi.spyOn(progressBar, 'hide').mockImplementation(() => undefined);

    target = document.createElement('div');
    target.id = 'dialog-target';
    document.body.appendChild(target);

    ctx = await setupStimulusTest({ controllers: { 'async-dialog': AsyncDialogController } });
  });

  const renderedChunks = () => target.querySelectorAll('.chunk').length;
  const flush = () => new Promise((resolve) => { setTimeout(resolve, 20); });

  // Streams render on the next repaint; let a test's last one land in its
  // own target instead of the next test's.
  afterEach(async () => {
    await flush();
    ctx.dispose();
    target.remove();
    vi.restoreAllMocks();
  });

  async function mountLink(attributes = ''):Promise<HTMLAnchorElement> {
    await ctx.mount(`<a href="/dialogs/new" data-controller="async-dialog" ${attributes}>Open</a>`);

    return ctx.container.querySelector('a')!;
  }

  it('requests the stream on click and renders it', async () => {
    const link = await mountLink('data-turbo-method="post"');

    link.click();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    const [url, init] = fetchSpy.mock.lastCall as [string, RequestInit & { headers:Headers }];
    expect(url).toBe(link.href);
    expect(init.method).toBe('POST');
    expect(init.headers.get('Accept')).toBe('text/vnd.turbo-stream.html, text/html, application/xhtml+xml');
    expect(init.headers.has('X-Requested-With')).toBe(false);
  });

  it('disables the trigger while loading and re-enables it afterwards', async () => {
    let resolveFetch!:(response:Response) => void;
    fetchSpy.mockImplementationOnce(() => new Promise<Response>((resolve) => { resolveFetch = resolve; }));
    const link = await mountLink();

    link.click();
    link.click();

    expect(link.getAttribute('aria-disabled')).toBe('true');
    expect(fetchSpy).toHaveBeenCalledOnce();

    resolveFetch(streamResponse());

    await waitFor(() => { expect(link.hasAttribute('aria-disabled')).toBe(false); });
    expect(hideSpy).toHaveBeenCalledOnce();
  });

  it.each([422, 500])('renders an HTTP %s stream exactly once', async (status) => {
    fetchSpy.mockResolvedValueOnce(streamResponse(status));
    const link = await mountLink();

    link.click();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    await flush();
    expect(renderedChunks()).toBe(1);
    expect(link.hasAttribute('aria-disabled')).toBe(false);
  });

  it('logs and cleans up when the response is not a stream', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fetchSpy.mockResolvedValueOnce(new Response('<p>Login</p>', { status: 200, headers: { 'Content-Type': 'text/html' } }));
    const link = await mountLink();

    link.click();

    await waitFor(() => { expect(consoleError).toHaveBeenCalledOnce(); });
    expect(renderedChunks()).toBe(0);
    expect(link.hasAttribute('aria-disabled')).toBe(false);
    expect(hideSpy).toHaveBeenCalledOnce();
  });

  it('logs and cleans up when the request fails', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));
    const link = await mountLink();

    link.click();

    await waitFor(() => { expect(consoleError).toHaveBeenCalledOnce(); });
    expect(link.hasAttribute('aria-disabled')).toBe(false);
    expect(hideSpy).toHaveBeenCalledOnce();
  });

  it('keeps the progress bar until every concurrent dialog request has settled', async () => {
    const resolvers:((response:Response) => void)[] = [];
    fetchSpy.mockImplementation(() => new Promise<Response>((resolve) => { resolvers.push(resolve); }));
    const link = await mountLink('data-async-dialog-disable-during-load-value="false"');

    link.click();
    link.click();

    expect(fetchSpy).toHaveBeenCalledTimes(2);

    resolvers[0](streamResponse());
    await flush();

    expect(hideSpy).not.toHaveBeenCalled();

    resolvers[1](streamResponse());
    await waitFor(() => { expect(hideSpy).toHaveBeenCalledOnce(); });
  });

  it('opens a dialog for a custom URL from an event', async () => {
    await mountLink();
    const controller = ctx.getController<AsyncDialogController>('async-dialog');

    controller.handleOpenDialog(new CustomEvent('open', { detail: { url: '/dialogs/42/edit' } }));

    await waitFor(() => { expect(fetchSpy).toHaveBeenCalledWith('/dialogs/42/edit', expect.anything()); });
  });
});
