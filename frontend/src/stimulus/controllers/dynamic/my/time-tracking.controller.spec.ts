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
import { type ActionEvent } from '@hotwired/stimulus';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type MyTimeTrackingControllerType from './time-tracking.controller';

const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const NEGOTIATED_ACCEPT = 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml';
const STREAM_HTML = '<turbo-stream action="append" target="stream-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': STREAM_CONTENT_TYPE } });
}

function htmlResponse():Response {
  return new Response('<p>Login</p>', { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}

describe('My time tracking controller', () => {
  let ctx:StimulusTestContext;
  let MyTimeTrackingController:typeof MyTimeTrackingControllerType;
  let request:Mock;
  let myTimeTrackingRefresh:Mock;
  let originalOpenProject:typeof window.OpenProject;
  let fetchSpy:Mock;
  let target:HTMLElement;
  let csrfMeta:HTMLMetaElement;
  const pathHelperService = {
    timeEntryDialog: () => '/time_entries/dialog',
    timeEntryUpdate: (id:string) => `/time_entries/${id}`,
    myTimeTrackingRefresh: undefined as unknown as Mock,
  };

  beforeAll(async () => {
    ({ default: MyTimeTrackingController } = await import('./time-tracking.controller'));
  });

  beforeEach(async () => {
    request = vi.fn().mockResolvedValue({ html: '', headers: new Headers() });
    myTimeTrackingRefresh = vi.fn().mockReturnValue('/my/time_tracking/refresh?date=2026-06-01');
    pathHelperService.myTimeTrackingRefresh = myTimeTrackingRefresh;

    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(streamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    target = document.createElement('div');
    target.id = 'stream-target';
    document.body.appendChild(target);

    csrfMeta = document.createElement('meta');
    csrfMeta.name = 'csrf-token';
    csrfMeta.content = 'token-123';
    document.head.appendChild(csrfMeta);

    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: { turboRequests: { request }, pathHelperService },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'my--time-tracking': MyTimeTrackingController },
    });
  });

  const flush = () => new Promise((resolve) => { setTimeout(resolve, 20); });

  afterEach(async () => {
    await flush();
    ctx.dispose();
    target.remove();
    csrfMeta.remove();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  // The calendar view needs FullCalendar; the list view exercises the
  // service wiring without it.
  async function renderListView() {
    await ctx.mount(`
      <div data-controller="my--time-tracking"
           data-my--time-tracking-view-mode-value="list"
           data-my--time-tracking-mode-value="week"></div>
    `);
    return ctx.getController<MyTimeTrackingControllerType>('my--time-tracking');
  }

  function dialogClosed(detail:object) {
    document.dispatchEvent(new CustomEvent('dialog:close', { detail }));
  }

  it('binds the declared services after connect', async () => {
    const controller = await renderListView();

    await expect(controller.services).resolves.toMatchObject({
      turboRequests: { request },
    });
  });

  it('requests the time entry dialog for a new time entry', async () => {
    const controller = await renderListView();

    void controller.newTimeEntry({ params: { date: '2026-06-01' } } as unknown as ActionEvent);

    await waitFor(() => {
      expect(request).toHaveBeenCalledWith(
        '/time_entries/dialog?onlyMe=true&date=2026-06-01',
        { method: 'GET' },
      );
    });
  });

  it('refreshes the list when the time entry dialog was submitted', async () => {
    const controller = await renderListView();
    await waitFor(() => { expect(controller.turboRequests).toBeDefined(); });

    dialogClosed({
      dialog: { id: 'time-entry-dialog' },
      additional: { spent_on: '2026-06-01' },
      submitted: true,
    });

    await waitFor(() => {
      expect(request).toHaveBeenCalledWith('/my/time_tracking/refresh?date=2026-06-01', { method: 'GET' });
    });
    expect(myTimeTrackingRefresh).toHaveBeenCalledWith('2026-06-01', 'list', 'week');
  });

  it('ignores dialog close events arriving before the context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    await renderListView();
    const root = ctx.container.querySelector('[data-controller="my--time-tracking"]')!;

    dialogClosed({
      dialog: { id: 'time-entry-dialog' },
      additional: { spent_on: '2026-06-01' },
      submitted: true,
    });

    root.remove();
    await ctx.nextFrame();

    resolveContext({
      services: {
        turboRequests: { request },
        pathHelperService,
      },
    });
    await ctx.nextFrame();

    expect(request).not.toHaveBeenCalled();
  });

  describe('updateTimeEntry', () => {
    const renderedChunks = () => target.querySelectorAll('.chunk').length;
    const lastCall = () => fetchSpy.mock.lastCall as [string, RequestInit & { headers:Headers, body:string }];

    async function renderReadyController() {
      const controller = await renderListView();
      await waitFor(() => { expect(controller.pathHelperService).toBeDefined(); });
      return controller;
    }

    it('patches the entry as JSON and renders the stream', async () => {
      const controller = await renderReadyController();
      const revert = vi.fn();

      controller.updateTimeEntry('5', '2026-06-01', '09:00', 1.5, revert);

      await waitFor(() => { expect(renderedChunks()).toBe(1); });
      const [url, init] = lastCall();
      expect(url).toBe('/time_entries/5');
      expect(init.method).toBe('PATCH');
      expect(init.headers.get('Content-Type')).toBe('application/json');
      expect(init.headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
      expect(init.headers.get('X-CSRF-Token')).toBe('token-123');
      expect(JSON.parse(init.body)).toEqual({
        time_entry: { spent_on: '2026-06-01', start_time: '09:00', hours: 1.5 },
        no_dialog: true,
      });
      await flush();
      expect(revert).not.toHaveBeenCalled();
    });

    it('sends a null start time for all-day entries', async () => {
      const controller = await renderReadyController();

      controller.updateTimeEntry('5', '2026-06-01', null, 8, vi.fn());

      await waitFor(() => { expect(fetchSpy).toHaveBeenCalledOnce(); });
      expect(JSON.parse(lastCall()[1].body).time_entry.start_time).toBeNull();
    });

    it.each([422, 500])('renders an HTTP %i stream once and reverts the event', async (status) => {
      fetchSpy.mockResolvedValueOnce(streamResponse(status));
      const controller = await renderReadyController();
      const revert = vi.fn();

      controller.updateTimeEntry('5', '2026-06-01', '09:00', 1.5, revert);

      await waitFor(() => { expect(revert).toHaveBeenCalledOnce(); });
      await waitFor(() => { expect(renderedChunks()).toBe(1); });
      await flush();
      expect(renderedChunks()).toBe(1);
    });

    it('renders nothing for a non-stream response and keeps the event', async () => {
      fetchSpy.mockResolvedValueOnce(htmlResponse());
      const controller = await renderReadyController();
      const revert = vi.fn();

      controller.updateTimeEntry('5', '2026-06-01', '09:00', 1.5, revert);

      await waitFor(() => { expect(fetchSpy).toHaveBeenCalledOnce(); });
      await flush();
      expect(renderedChunks()).toBe(0);
      expect(revert).not.toHaveBeenCalled();
    });

    it('reverts the event when the request fails', async () => {
      fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));
      const controller = await renderReadyController();
      const revert = vi.fn();

      controller.updateTimeEntry('5', '2026-06-01', '09:00', 1.5, revert);

      await waitFor(() => { expect(revert).toHaveBeenCalledOnce(); });
      expect(renderedChunks()).toBe(0);
    });
  });
});
