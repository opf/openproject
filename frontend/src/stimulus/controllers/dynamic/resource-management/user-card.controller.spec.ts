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
import UserCardController from './user-card.controller';

const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const NEGOTIATED_ACCEPT = 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml';
const STREAM_HTML = '<turbo-stream action="append" target="stream-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': STREAM_CONTENT_TYPE } });
}

function htmlResponse():Response {
  return new Response('<p>Login</p>', { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}

describe('UserCardController', () => {
  let ctx:StimulusTestContext;
  let fetchSpy:Mock;
  let target:HTMLElement;

  beforeEach(async () => {
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(streamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    target = document.createElement('div');
    target.id = 'stream-target';
    document.body.appendChild(target);

    ctx = await setupStimulusTest({ controllers: { 'resource-management--user-card': UserCardController } });
    await ctx.mount(`
      <div data-controller="resource-management--user-card"
           data-resource-management--user-card-url-value="/resource_planners/1/users/2/allocations">
        <span class="name">Ada</span>
        <button type="button" class="remove">Remove</button>
      </div>
    `);
  });

  const flush = () => new Promise((resolve) => { setTimeout(resolve, 20); });

  afterEach(async () => {
    await flush();
    ctx.dispose();
    target.remove();
    vi.restoreAllMocks();
  });

  const renderedChunks = () => target.querySelectorAll('.chunk').length;
  const card = () => ctx.container.querySelector<HTMLElement>('[data-controller]')!;
  const lastCall = () => fetchSpy.mock.lastCall as [string, RequestInit & { headers:Headers }];

  it('requests the details dialog as a stream when the card is clicked', async () => {
    card().querySelector<HTMLElement>('.name')!.click();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    const [url, init] = lastCall();
    expect(url).toBe('/resource_planners/1/users/2/allocations');
    expect(init.method).toBe('GET');
    expect(init.headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
    expect(init.headers.has('X-CSRF-Token')).toBe(false);
  });

  it('ignores clicks on interactive elements inside the card', async () => {
    card().querySelector<HTMLElement>('.remove')!.click();
    await ctx.nextFrame();

    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it.each([422, 500])('renders an HTTP %i stream exactly once', async (status) => {
    fetchSpy.mockResolvedValueOnce(streamResponse(status));

    card().click();

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    await flush();
    expect(renderedChunks()).toBe(1);
  });

  it('logs instead of rendering a non-stream response', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fetchSpy.mockResolvedValueOnce(htmlResponse());

    card().click();

    await waitFor(() => { expect(consoleError).toHaveBeenCalledOnce(); });
    expect(renderedChunks()).toBe(0);
  });

  it('logs when the request fails', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));

    card().click();

    await waitFor(() => { expect(consoleError).toHaveBeenCalledOnce(); });
  });
});
