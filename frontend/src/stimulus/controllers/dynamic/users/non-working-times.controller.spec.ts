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
import NonWorkingTimesController from './non-working-times.controller';

const STREAM_HTML = '<turbo-stream action="append" target="non-working-dialog-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': 'text/vnd.turbo-stream.html; charset=utf-8' } });
}

describe('NonWorkingTimesController', () => {
  const progressBar = (Turbo.session.adapter as Turbo.BrowserAdapter).progressBar;
  const calendar = { destroy: vi.fn() };
  let ctx:StimulusTestContext;
  let fetchSpy:Mock;
  let hideSpy:ReturnType<typeof vi.spyOn>;
  let target:HTMLElement;

  beforeEach(async () => {
    vi.spyOn(NonWorkingTimesController.prototype, 'initializeCalendar')
      .mockImplementation(function stubInitializeCalendar(this:{ calendar:unknown }) {
        this.calendar = calendar;
      });

    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(streamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);
    vi.spyOn(progressBar, 'setValue').mockImplementation(() => undefined);
    vi.spyOn(progressBar, 'show').mockImplementation(() => undefined);
    hideSpy = vi.spyOn(progressBar, 'hide').mockImplementation(() => undefined);

    target = document.createElement('div');
    target.id = 'non-working-dialog-target';
    document.body.appendChild(target);

    ctx = await setupStimulusTest({ controllers: { 'users--non-working-times': NonWorkingTimesController } });
    await ctx.mount(`
      <div data-controller="users--non-working-times"
           data-users--non-working-times-year-value="2026"
           data-users--non-working-times-locale-value="en">
        <div data-users--non-working-times-target="calendar"></div>
      </div>
    `);
  });

  afterEach(() => {
    ctx.dispose();
    target.remove();
    vi.restoreAllMocks();
  });

  const renderedChunks = () => target.querySelectorAll('.chunk').length;
  const openDialog = (url:string) => {
    const controller = ctx.getController<NonWorkingTimesController>('users--non-working-times');
    const method = Reflect.get(controller, 'openDialog') as (this:NonWorkingTimesController, url:string) => void;

    method.call(controller, url);
  };

  it('requests the dialog as a stream and renders it', async () => {
    openDialog('/non_working_days/new?start_date=2026-12-24');

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    const [url, init] = fetchSpy.mock.lastCall as [string, RequestInit & { headers:Headers }];
    expect(url).toBe('/non_working_days/new?start_date=2026-12-24');
    expect(init.method).toBe('GET');
    expect(init.headers.get('Accept')).toBe('text/vnd.turbo-stream.html, text/html, application/xhtml+xml');
    await waitFor(() => { expect(hideSpy).toHaveBeenCalledOnce(); });
  });

  it('renders error streams for failed requests', async () => {
    fetchSpy.mockResolvedValueOnce(streamResponse(500));

    openDialog('/non_working_days/1/edit');

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    await waitFor(() => { expect(hideSpy).toHaveBeenCalledOnce(); });
  });

  it('logs and hides progress when the response is not a stream', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fetchSpy.mockResolvedValueOnce(new Response('<p>Login</p>', { status: 200, headers: { 'Content-Type': 'text/html' } }));

    openDialog('/non_working_days/1/edit');

    await waitFor(() => { expect(consoleError).toHaveBeenCalledOnce(); });
    expect(renderedChunks()).toBe(0);
    expect(hideSpy).toHaveBeenCalledOnce();
  });

  it('logs and hides progress when the request fails', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));

    openDialog('/non_working_days/1/edit');

    await waitFor(() => { expect(consoleError).toHaveBeenCalledOnce(); });
    expect(hideSpy).toHaveBeenCalledOnce();
  });
});
