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

import { TestBed } from '@angular/core/testing';
import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { TurboHelpers } from 'core-turbo/helpers';
import { TurboRequestError } from 'core-turbo/turbo-request-error';
import { TurboRequestsService } from './turbo-requests.service';

const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const STREAM_HTML = '<turbo-stream action="append" target="service-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse(status = 200):Response {
  return new Response(STREAM_HTML, { status, headers: { 'Content-Type': STREAM_CONTENT_TYPE } });
}

function htmlResponse(status = 200, html = '<p>Plain page</p>'):Response {
  return new Response(html, { status, headers: { 'Content-Type': 'text/html; charset=utf-8', 'X-Custom': 'yes' } });
}

describe('TurboRequestsService', () => {
  let service:TurboRequestsService;
  let fetchSpy:Mock;
  let addError:Mock;
  let target:HTMLElement;
  let csrfMeta:HTMLMetaElement;

  beforeEach(() => {
    addError = vi.fn();
    TestBed.configureTestingModule({
      providers: [
        TurboRequestsService,
        { provide: ToastService, useValue: { addError } },
      ],
    });
    service = TestBed.inject(TurboRequestsService);

    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(htmlResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    target = document.createElement('div');
    target.id = 'service-target';
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
  const flush = () => new Promise((resolve) => { setTimeout(resolve, 20); });

  describe('request', () => {
    it('resolves with the response text and headers', async () => {
      const result = await service.request('/page');

      expect(result.html).toBe('<p>Plain page</p>');
      expect(result.headers.get('X-Custom')).toBe('yes');
      expect(renderedChunks()).toBe(0);
    });

    it('sends legacy requests with browser defaults and the CSRF token on unsafe methods', async () => {
      await service.request('/page', { method: 'POST' });

      expect(lastInit().method).toBe('POST');
      expect(lastInit().headers.get('X-CSRF-Token')).toBe('token-123');
      expect(lastInit().headers.has('Accept')).toBe(false);
      expect(lastInit().headers.has('X-Requested-With')).toBe(false);

      await service.request('/page');

      expect(lastInit().headers.has('X-CSRF-Token')).toBe(false);
    });

    it('renders a successful stream once and resolves', async () => {
      fetchSpy.mockResolvedValueOnce(streamResponse());

      const result = await service.request('/dialog');

      await waitFor(() => { expect(renderedChunks()).toBe(1); });
      await flush();
      expect(renderedChunks()).toBe(1);
      expect(result.html).toBe(STREAM_HTML);
    });

    it('renders a 422 stream once and rejects with the status', async () => {
      fetchSpy.mockResolvedValueOnce(streamResponse(422));

      const pending = service.request('/form');

      await expect(pending).rejects.toBeInstanceOf(TurboRequestError);
      await expect(pending).rejects.toMatchObject({ status: 422 });
      await waitFor(() => { expect(renderedChunks()).toBe(1); });
      await flush();
      expect(renderedChunks()).toBe(1);
      expect(addError).toHaveBeenCalledOnce();
    });

    it('renders other error streams once and rejects with the status', async () => {
      fetchSpy.mockResolvedValueOnce(streamResponse(500));

      await expect(service.request('/form')).rejects.toMatchObject({ status: 500 });
      await waitFor(() => { expect(renderedChunks()).toBe(1); });
      await flush();
      expect(renderedChunks()).toBe(1);
    });

    it('rejects non-stream HTTP errors with a TurboRequestError', async () => {
      fetchSpy.mockResolvedValueOnce(htmlResponse(404));

      await expect(service.request('/missing')).rejects.toMatchObject({ status: 404, name: 'TurboRequestError' });
      expect(renderedChunks()).toBe(0);
    });

    it('logs instead of toasting when the toast is suppressed', async () => {
      const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
      fetchSpy.mockResolvedValueOnce(htmlResponse(500));

      await expect(service.request('/missing', {}, true)).rejects.toMatchObject({ status: 500 });

      expect(addError).not.toHaveBeenCalled();
      expect(consoleError).toHaveBeenCalledOnce();
    });

    it('does not treat an authentication challenge as a redirect', async () => {
      const href = window.location.href;
      fetchSpy.mockResolvedValueOnce(new Response('', { status: 401, headers: { 'WWW-Authenticate': 'Bearer realm="OpenProject API"' } }));

      await expect(service.request('/protected')).rejects.toMatchObject({ status: 401 });

      expect(window.location.href).toBe(href);
    });
  });

  describe('cancellation', () => {
    function pendingFetch() {
      let signal:AbortSignal|undefined;
      let reject!:(error:Error) => void;
      fetchSpy.mockImplementationOnce((_url:string, init:RequestInit) => {
        signal = init.signal ?? undefined;

        return new Promise<Response>((_resolve, rej) => { reject = rej; });
      });

      return {
        get signal() { return signal; },
        abort: () => reject(new DOMException('The operation was aborted.', 'AbortError')),
      };
    }

    it('aborts the previous request with the same id', async () => {
      const first = pendingFetch();
      const firstRequest = service.request('/a', {}, false, 'slot');
      const second = pendingFetch();
      const secondRequest = service.request('/a', {}, false, 'slot');

      expect(first.signal?.aborted).toBe(true);
      expect(second.signal?.aborted).toBe(false);

      first.abort();
      await expect(firstRequest).rejects.toMatchObject({ name: 'AbortError' });
      expect(addError).not.toHaveBeenCalled();

      second.abort();
      await expect(secondRequest).rejects.toMatchObject({ name: 'AbortError' });
    });

    it('keeps the replacement request abortable after the replaced one settles', async () => {
      const first = pendingFetch();
      const firstRequest = service.request('/a', {}, false, 'slot');
      const second = pendingFetch();
      const secondRequest = service.request('/a', {}, false, 'slot');

      first.abort();
      await expect(firstRequest).rejects.toMatchObject({ name: 'AbortError' });

      service.abortRequest('slot');

      expect(second.signal?.aborted).toBe(true);

      second.abort();
      await expect(secondRequest).rejects.toMatchObject({ name: 'AbortError' });
    });

    it('aborts every tracked request', async () => {
      const first = pendingFetch();
      const firstRequest = service.request('/a', {}, false, 'one');
      const second = pendingFetch();
      const secondRequest = service.request('/b', {}, false, 'two');

      service.abortAll();

      expect(first.signal?.aborted).toBe(true);
      expect(second.signal?.aborted).toBe(true);

      first.abort();
      second.abort();
      await expect(firstRequest).rejects.toMatchObject({ name: 'AbortError' });
      await expect(secondRequest).rejects.toMatchObject({ name: 'AbortError' });
    });
  });

  describe('requestStream', () => {
    it('asks for a stream and shows progress for the whole request', async () => {
      const showSpy = vi.spyOn(TurboHelpers, 'showProgressBar').mockImplementation(() => undefined);
      const hideSpy = vi.spyOn(TurboHelpers, 'hideProgressBar').mockImplementation(() => undefined);
      fetchSpy.mockResolvedValueOnce(streamResponse());

      await service.requestStream('/dialog');

      expect(lastInit().headers.get('Accept')).toBe('text/vnd.turbo-stream.html, text/html, application/xhtml+xml');
      expect(lastInit().credentials).toBe('same-origin');
      expect(showSpy).toHaveBeenCalledOnce();
      expect(hideSpy).toHaveBeenCalledOnce();
    });
  });

  describe('submitForm', () => {
    it('posts the form data to the form action with extra params', async () => {
      const form = document.createElement('form');
      form.method = 'post';
      form.action = '/forms/1';
      form.innerHTML = '<input name="title" value="Sprint">';
      document.body.appendChild(form);

      await service.submitForm(form, new URLSearchParams({ preview: 'true' }));

      const [url, init] = fetchSpy.mock.lastCall as [string, RequestInit];
      expect(url).toBe(`${form.action}?preview=true`);
      expect(init.method).toBe('POST');
      expect((init.body as FormData).get('title')).toBe('Sprint');
      form.remove();
    });
  });
});
