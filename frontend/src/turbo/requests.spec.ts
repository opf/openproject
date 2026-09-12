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

import { renderStreamMessage } from '@hotwired/turbo';
import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';
import { TurboHelpers } from 'core-turbo/helpers';
import { TurboRequestScope } from 'core-turbo/request-scope';
import {
  isTurboStream,
  renderErrorStream,
  request,
} from './requests';

const TURBO_STREAM_ACCEPT = 'text/vnd.turbo-stream.html';
const NEGOTIATED_ACCEPT = 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml';
const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const STREAM_HTML = '<turbo-stream action="append" target="stream-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200, headers:Record<string, string> = {}):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': STREAM_CONTENT_TYPE, ...headers } });
}

function htmlResponse(status = 200):Response {
  return new Response('<p>Plain page</p>', { status, headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}

describe('turbo/requests', () => {
  let fetchSpy:Mock;
  let target:HTMLElement;
  let csrfMeta:HTMLMetaElement;

  beforeEach(() => {
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(streamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    target = document.createElement('div');
    target.id = 'stream-target';
    document.body.appendChild(target);

    csrfMeta = document.createElement('meta');
    csrfMeta.name = 'csrf-token';
    csrfMeta.content = 'token-123';
    document.head.appendChild(csrfMeta);
  });

  afterEach(() => {
    target.remove();
    csrfMeta.remove();
    vi.restoreAllMocks();
  });

  const renderedChunks = () => target.querySelectorAll('.chunk').length;
  const lastInit = () => fetchSpy.mock.lastCall?.[1] as RequestInit & { headers:Headers };
  const lastUrl = () => fetchSpy.mock.lastCall?.[0] as string|URL;
  const flush = () => new Promise((resolve) => { setTimeout(resolve, 20); });

  describe('rendering', () => {
    it('renders a successful stream exactly once and resolves with the response', async () => {
      const response = await request('/dialog');

      await waitFor(() => { expect(renderedChunks()).toBe(1); });
      await flush();
      expect(renderedChunks()).toBe(1);
      expect(response.succeeded).toBe(true);
      expect(isTurboStream(response)).toBe(true);
      expect(await response.responseText).toBe(STREAM_HTML);
    });

    it('renders a 422 stream', async () => {
      fetchSpy.mockResolvedValueOnce(streamResponse(422));

      const response = await request('/form');

      await waitFor(() => { expect(renderedChunks()).toBe(1); });
      expect(response.statusCode).toBe(422);
    });

    it('resolves without rendering for other error streams', async () => {
      fetchSpy.mockResolvedValueOnce(streamResponse(500));

      const response = await request('/form');
      await flush();

      expect(response.failed).toBe(true);
      expect(response.statusCode).toBe(500);
      expect(renderedChunks()).toBe(0);
    });

    it('does not render or reject non-stream responses by default', async () => {
      fetchSpy.mockResolvedValueOnce(htmlResponse());

      const response = await request('/page');
      await flush();

      expect(renderedChunks()).toBe(0);
      expect(isTurboStream(response)).toBe(false);
      expect(await response.responseText).toBe('<p>Plain page</p>');
    });

    it.each([200, 500])('leaves HTML fallback readable with a stream preference and status %i', async (status) => {
      fetchSpy.mockResolvedValueOnce(htmlResponse(status));
      const init = { method: 'GET', responseKind: 'turbo-stream' as const };

      const response = await request('/dialog', init);
      await flush();

      expect(response.statusCode).toBe(status);
      expect(await response.responseText).toBe('<p>Plain page</p>');
      expect(renderedChunks()).toBe(0);
    });

    it('treats authentication challenges as ordinary responses', async () => {
      const href = window.location.href;

      for (const challenge of ['Bearer realm="OpenProject API"', 'Basic realm="OpenProject API"']) {
        fetchSpy.mockResolvedValueOnce(new Response('', { status: 401, headers: { 'WWW-Authenticate': challenge } }));

        const response = await request('/protected');

        expect(response.statusCode).toBe(401);
        expect(response.header('WWW-Authenticate')).toBe(challenge);
      }

      expect(window.location.href).toBe(href);
    });

    it('propagates network failures', async () => {
      fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));

      await expect(request('/down')).rejects.toThrow('Failed to fetch');
    });
  });

  describe('Turbo request tracking', () => {
    const requestIdOf = () => lastInit().headers.get('X-Turbo-Request-Id') ?? '';
    // A stream element removes itself once its action has run; the refresh
    // action then debounces the page refresh, so a timer started after the
    // removal outlasts it.
    const renderRefreshStream = async (requestId:string) => {
      renderStreamMessage(`<turbo-stream action="refresh" request-id="${requestId}"></turbo-stream>`);
      expect(document.querySelector('turbo-stream')).not.toBeNull();
      await waitFor(() => { expect(document.querySelector('turbo-stream')).toBeNull(); });
    };
    const outlastRefreshDebounce = () => new Promise((resolve) => { setTimeout(resolve, 400); });
    let proposedVisits:number;
    const cancelVisit = (event:Event) => {
      proposedVisits += 1;
      event.preventDefault();
    };

    beforeEach(() => {
      proposedVisits = 0;
      document.addEventListener('turbo:before-visit', cancelVisit);
    });

    afterEach(() => {
      document.removeEventListener('turbo:before-visit', cancelVisit);
    });

    it('tags every request with its own Turbo request id', async () => {
      await request('/a');
      const first = requestIdOf();

      await request('/b');

      expect(first).toMatch(/\S/);
      expect(requestIdOf()).toMatch(/\S/);
      expect(requestIdOf()).not.toBe(first);
    });

    it('lets Turbo skip a refresh stream caused by its own request', async () => {
      await request('/a');
      const requestId = requestIdOf();

      await renderRefreshStream('some-other-request');
      await waitFor(() => { expect(proposedVisits).toBe(1); });

      await renderRefreshStream(requestId);
      await outlastRefreshDebounce();
      expect(proposedVisits).toBe(1);
    });

    it('reads the response body repeatedly after rendering', async () => {
      for (const status of [200, 422, 500]) {
        fetchSpy.mockResolvedValueOnce(streamResponse(status));

        const response = await request('/form');

        expect(await response.responseText).toBe(STREAM_HTML);
        expect(await response.responseText).toBe(STREAM_HTML);
      }

      await waitFor(() => { expect(renderedChunks()).toBe(2); });
    });
  });

  describe('renderErrorStream', () => {
    it('renders the stream of a non-422 error response once', async () => {
      fetchSpy.mockResolvedValueOnce(streamResponse(403));
      const response = await request('/forbidden');

      await expect(renderErrorStream(response)).resolves.toBe(true);
      await waitFor(() => { expect(renderedChunks()).toBe(1); });
      await flush();
      expect(renderedChunks()).toBe(1);
    });

    it('leaves already rendered and non-stream responses alone', async () => {
      const rendered = await request('/dialog');
      await expect(renderErrorStream(rendered)).resolves.toBe(false);

      fetchSpy.mockResolvedValueOnce(streamResponse(422));
      const unprocessable = await request('/form');
      await expect(renderErrorStream(unprocessable)).resolves.toBe(false);

      fetchSpy.mockResolvedValueOnce(htmlResponse(500));
      const html = await request('/page');
      await expect(renderErrorStream(html)).resolves.toBe(false);

      await waitFor(() => { expect(renderedChunks()).toBe(2); });
      await flush();
      expect(renderedChunks()).toBe(2);
    });
  });

  describe('request shape', () => {
    it('passes the URL through untouched', async () => {
      const url = '/work_packages?filters[]=status%3Dopen&filters[]=type%3Dbug#details';

      await request(url);

      expect(lastUrl()).toBe(url);
    });

    it('passes URL objects through untouched', async () => {
      const url = new URL('/dialog?x=1', window.location.origin);

      await request(url);

      expect(lastUrl()).toBe(url);
    });

    it('preserves native body encoding', async () => {
      const params = new URLSearchParams({ query: 'a b' });
      await request('/query', { method: 'PATCH', body: params });
      expect(lastInit().body).toBe(params);

      const formData = new FormData();
      formData.append('name', 'x');
      await request('/form', { method: 'POST', body: formData });
      expect(lastInit().body).toBe(formData);

      await request('/json', { method: 'POST', body: '{"a":1}', headers: { 'Content-Type': 'application/json' } });
      expect(lastInit().body).toBe('{"a":1}');
      expect(lastInit().headers.get('Content-Type')).toBe('application/json');
    });

    it('adds no default Accept or XHR headers', async () => {
      await request('/legacy', { method: 'POST' });

      expect(lastInit().headers.has('Accept')).toBe(false);
      expect(lastInit().headers.has('X-Requested-With')).toBe(false);
    });

    it('keeps explicit headers from every HeadersInit shape', async () => {
      await request('/a', { headers: { Accept: TURBO_STREAM_ACCEPT } });
      expect(lastInit().headers.get('Accept')).toBe(TURBO_STREAM_ACCEPT);

      await request('/b', { headers: [['Accept', TURBO_STREAM_ACCEPT]] });
      expect(lastInit().headers.get('Accept')).toBe(TURBO_STREAM_ACCEPT);

      await request('/c', { headers: new Headers({ Accept: TURBO_STREAM_ACCEPT }) });
      expect(lastInit().headers.get('Accept')).toBe(TURBO_STREAM_ACCEPT);

      await request('/d', { headers: { Accept: NEGOTIATED_ACCEPT, 'X-Requested-With': 'XMLHttpRequest' } });
      expect(lastInit().headers.get('Accept')).toBe('text/vnd.turbo-stream.html, text/html, application/xhtml+xml');
      expect(lastInit().headers.get('X-Requested-With')).toBe('XMLHttpRequest');
    });

    it('negotiates stream and HTML responses without adding XHR headers', async () => {
      const init = { method: 'GET', responseKind: 'turbo-stream' as const };

      await request('/dialog', init);

      expect(lastInit().headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
      expect(lastInit().headers.has('X-Requested-With')).toBe(false);
    });

    it('overrides conflicting Accept headers from every HeadersInit shape', async () => {
      const headerShapes:HeadersInit[] = [
        { Accept: 'application/json', 'Content-Type': 'application/json' },
        [['accept', 'application/json'], ['Content-Type', 'application/json']],
        new Headers({ Accept: 'application/json', 'Content-Type': 'application/json' }),
      ];

      for (const headers of headerShapes) {
        const init = { headers, responseKind: 'turbo-stream' as const };
        await request('/dialog', init);

        expect(lastInit().headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
        expect(lastInit().headers.get('Content-Type')).toBe('application/json');
        expect(new Headers(headers).get('Accept')).toBe('application/json');
      }
    });

    it('preserves native bodies with a stream preference', async () => {
      const formData = new FormData();
      formData.append('name', 'x');

      for (const body of [new URLSearchParams({ query: 'a b' }), formData, '{"a":1}']) {
        const init = { method: 'POST', body, responseKind: 'turbo-stream' as const };
        await request('/form', init);

        expect(lastInit().body).toBe(body);
        expect(lastInit().headers.has('Content-Type')).toBe(false);
      }
    });

    it('strips custom options without mutating the supplied init', async () => {
      const scope = new TurboRequestScope();
      const headers = new Headers({ Accept: 'application/json' });
      const init = Object.freeze({
        method: 'post',
        headers,
        responseKind: 'turbo-stream' as const,
        progress: false,
        scope,
      });

      await request('/form', init);

      expect(lastInit()).not.toHaveProperty('responseKind');
      expect(lastInit()).not.toHaveProperty('progress');
      expect(lastInit()).not.toHaveProperty('scope');
      expect(init.method).toBe('post');
      expect(init.responseKind).toBe('turbo-stream');
      expect(init.progress).toBe(false);
      expect(init.scope).toBe(scope);
      expect(init.headers).toBe(headers);
      expect(headers.get('Accept')).toBe('application/json');
      expect(headers.has('X-CSRF-Token')).toBe(false);
    });

    it('passes the abort signal through', async () => {
      const controller = new AbortController();

      await request('/a', { signal: controller.signal });

      expect(lastInit().signal).toBe(controller.signal);
    });

    it('normalizes the method and defaults to GET', async () => {
      await request('/a');
      expect(lastInit().method).toBe('GET');

      await request('/b', { method: 'post' });
      expect(lastInit().method).toBe('POST');
    });
  });

  describe('CSRF token', () => {
    it('adds the meta token to same-origin unsafe requests', async () => {
      for (const method of ['post', 'PUT', 'PATCH', 'DELETE']) {
        await request('/a', { method });
        expect(lastInit().headers.get('X-CSRF-Token')).toBe('token-123');
      }

      await request(new URL('/a', window.location.origin), { method: 'POST' });
      expect(lastInit().headers.get('X-CSRF-Token')).toBe('token-123');
    });

    it('adds no token to safe methods', async () => {
      for (const method of [undefined, 'GET', 'HEAD', 'OPTIONS', 'TRACE']) {
        await request('/a', { method });
        expect(lastInit().headers.has('X-CSRF-Token')).toBe(false);
      }
    });

    it('keeps an explicit token', async () => {
      await request('/a', { method: 'POST', headers: { 'X-CSRF-Token': 'explicit' } });

      expect(lastInit().headers.get('X-CSRF-Token')).toBe('explicit');
    });

    it('adds no token to cross-origin requests', async () => {
      await request('https://example.test/a', { method: 'POST' });

      expect(lastInit().headers.has('X-CSRF-Token')).toBe(false);
    });

    it('adds no token when the page has none', async () => {
      csrfMeta.remove();

      await request('/a', { method: 'POST' });

      expect(lastInit().headers.has('X-CSRF-Token')).toBe(false);
    });
  });

  describe('progress', () => {
    let showSpy:ReturnType<typeof vi.spyOn>;
    let hideSpy:ReturnType<typeof vi.spyOn>;

    beforeEach(() => {
      showSpy = vi.spyOn(TurboHelpers, 'showProgressBar').mockImplementation(() => undefined);
      hideSpy = vi.spyOn(TurboHelpers, 'hideProgressBar').mockImplementation(() => undefined);
    });

    it('is off by default', async () => {
      await request('/a');

      expect(showSpy).not.toHaveBeenCalled();
      expect(hideSpy).not.toHaveBeenCalled();
    });

    it('shows the bar for the request and hides it once settled', async () => {
      let resolveFetch!:(response:Response) => void;
      fetchSpy.mockImplementationOnce(() => new Promise<Response>((resolve) => { resolveFetch = resolve; }));

      const init = { method: 'GET', progress: true };
      const pending = request('/a', init);

      expect(showSpy).toHaveBeenCalledOnce();
      expect(hideSpy).not.toHaveBeenCalled();

      resolveFetch(htmlResponse());
      await pending;

      expect(hideSpy).toHaveBeenCalledOnce();
    });

    it('hides the bar when the request fails', async () => {
      fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));

      const init = { method: 'GET', progress: true };
      await expect(request('/a', init)).rejects.toThrow();

      expect(hideSpy).toHaveBeenCalledOnce();
    });
  });

  describe('scope', () => {
    it('tracks the request on the given scope until it settles', async () => {
      const scope = new TurboRequestScope();
      let resolveFetch!:(response:Response) => void;
      fetchSpy.mockImplementationOnce(() => new Promise<Response>((resolve) => { resolveFetch = resolve; }));

      const init = { method: 'GET', scope };
      const pending = request('/a', init);

      expect(scope.busy).toBe(true);

      resolveFetch(htmlResponse());
      await pending;

      expect(scope.busy).toBe(false);
    });

    it('releases the scope when the request fails', async () => {
      const scope = new TurboRequestScope();
      fetchSpy.mockRejectedValueOnce(new TypeError('Failed to fetch'));

      const init = { method: 'GET', scope };
      await expect(request('/a', init)).rejects.toThrow();

      expect(scope.busy).toBe(false);
    });
  });
});
