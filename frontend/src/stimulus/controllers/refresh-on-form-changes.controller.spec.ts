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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { waitFor } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type RefreshOnFormChangesControllerType from './refresh-on-form-changes.controller';
import { serializeFormQuery } from './refresh-on-form-changes.controller';

describe('Refresh on form changes controller', () => {
  let ctx:StimulusTestContext;
  let RefreshOnFormChangesController:typeof RefreshOnFormChangesControllerType;
  let fetchSpy:Mock;
  let renderStreamMessage:Mock;
  let originalTurbo:typeof window.Turbo;

  beforeAll(async () => {
    ({ default: RefreshOnFormChangesController } = await import('./refresh-on-form-changes.controller'));
  });

  beforeEach(async () => {
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(turboStreamResponse()));
    renderStreamMessage = vi.fn().mockResolvedValue(undefined);

    originalTurbo = window.Turbo;
    window.Turbo = {
      ...originalTurbo,
      fetch: fetchSpy,
      renderStreamMessage,
    } as typeof window.Turbo;
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    ctx = await setupStimulusTest({
      controllers: { 'refresh-on-form-changes': RefreshOnFormChangesController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.Turbo = originalTurbo;
    vi.restoreAllMocks();
  });

  function turboStreamResponse(html = '<turbo-stream action="update" target="sprint-dialog-form"></turbo-stream>') {
    return new Response(html, {
      status: 200,
      headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
    });
  }

  async function renderForm() {
    await ctx.mount(`
      <form data-controller="refresh-on-form-changes"
            data-refresh-on-form-changes-target="form"
            data-refresh-on-form-changes-turbo-stream-url-value="/refresh">
        <input name="sprint[name]" value="Created sprint">
        <textarea name="sprint[goal][text]">Deliver the first MVP scope.</textarea>
      </form>
    `);

    return ctx.getController<RefreshOnFormChangesControllerType>('refresh-on-form-changes');
  }

  it('requests a turbo stream refresh with the current form data as query params', async () => {
    const controller = await renderForm();

    controller.triggerTurboStream();

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalled();
    });

    const [url, init] = fetchSpy.mock.calls[0] as [string, RequestInit];
    const parsedUrl = new URL(url, window.location.origin);

    expect(parsedUrl.pathname).toBe('/refresh');
    expect(parsedUrl.searchParams.get('sprint[name]')).toBe('Created sprint');
    expect(parsedUrl.searchParams.get('sprint[goal][text]')).toBe('Deliver the first MVP scope.');
    expect(init).toEqual(expect.objectContaining({
      method: 'GET',
      credentials: 'same-origin',
      headers: expect.objectContaining({
        Accept: 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml',
        'X-Requested-With': 'XMLHttpRequest',
      }) as HeadersInit,
    }));
    await waitFor(() => {
      expect(renderStreamMessage).toHaveBeenCalledWith(
        '<turbo-stream action="update" target="sprint-dialog-form"></turbo-stream>',
      );
    });
  });

  it('aborts an in-flight refresh before starting the next one', async () => {
    const controller = await renderForm();
    let firstReject!:(error:DOMException) => void;
    let firstSignal:AbortSignal|undefined;

    fetchSpy
      .mockImplementationOnce((_url:string, init:RequestInit) => {
        firstSignal = init.signal ?? undefined;

        return new Promise<Response>((_resolve, reject) => {
          firstReject = reject;
        });
      })
      .mockResolvedValueOnce(turboStreamResponse());

    controller.triggerTurboStream();
    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });

    controller.triggerTurboStream();
    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledTimes(2);
    });

    expect(firstSignal?.aborted).toBe(true);
    firstReject(new DOMException('The operation was aborted.', 'AbortError'));

    await waitFor(() => {
      expect(renderStreamMessage).toHaveBeenCalledOnce();
    });
  });

  it('aborts an in-flight refresh when disconnected', async () => {
    const controller = await renderForm();
    let signal:AbortSignal|undefined;

    fetchSpy.mockImplementationOnce((_url:string, init:RequestInit) => {
      signal = init.signal ?? undefined;

      return new Promise<Response>((resolve) => {
        void resolve;
      });
    });

    controller.triggerTurboStream();
    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledOnce();
    });

    ctx.container.querySelector('form')!.remove();
    await ctx.nextFrame();

    expect(signal?.aborted).toBe(true);
  });

  it('coalesces rapid refresh requests into a single request with the latest form data', async () => {
    const controller = await renderForm();
    const goalInput = ctx.container.querySelector<HTMLTextAreaElement>('[name="sprint[goal][text]"]')!;

    controller.triggerTurboStream();
    goalInput.value = 'Updated goal';
    controller.triggerTurboStream();

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledOnce();
    });
    const [url] = fetchSpy.mock.calls[0] as [string, RequestInit];
    const parsedUrl = new URL(url, window.location.origin);

    expect(parsedUrl.searchParams.get('sprint[goal][text]')).toBe('Updated goal');
  });

  describe('serializeFormQuery', () => {
    function buildForm(innerHtml:string):HTMLFormElement {
      const form = document.createElement('form');
      form.innerHTML = innerHtml;
      return form;
    }

    it('serializes string form fields into a query string', () => {
      const form = buildForm(`
        <input name="sprint[name]" value="Created sprint">
        <textarea name="sprint[goal][text]">Deliver the first MVP scope.</textarea>
      `);

      const params = new URLSearchParams(serializeFormQuery(form));

      expect(params.get('sprint[name]')).toBe('Created sprint');
      expect(params.get('sprint[goal][text]')).toBe('Deliver the first MVP scope.');
    });

    it('omits file inputs so File values never reach the query string', () => {
      const form = buildForm(`
        <input name="sprint[name]" value="Created sprint">
        <input type="file" name="sprint[attachment]">
      `);
      const fileInput = form.querySelector<HTMLInputElement>('[name="sprint[attachment]"]')!;
      const transfer = new DataTransfer();
      transfer.items.add(new File(['data'], 'report.pdf', { type: 'application/pdf' }));
      fileInput.files = transfer.files;

      const params = new URLSearchParams(serializeFormQuery(form));

      expect(params.has('sprint[attachment]')).toBe(false);
      expect(params.get('sprint[name]')).toBe('Created sprint');
    });
  });

  it('swallows abort errors but logs other request errors', async () => {
    const controller = await renderForm();
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);

    fetchSpy.mockRejectedValueOnce(new DOMException('The operation was aborted.', 'AbortError'));
    controller.triggerTurboStream();
    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledOnce();
    });
    expect(consoleError).not.toHaveBeenCalled();

    fetchSpy.mockRejectedValueOnce(new Error('network down'));
    controller.triggerTurboStream();
    await waitFor(() => {
      expect(consoleError).toHaveBeenCalledWith(new Error('network down'));
    });
  });
});
