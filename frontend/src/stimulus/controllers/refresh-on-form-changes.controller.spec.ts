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
import type RefreshOnFormChangesControllerType from './refresh-on-form-changes.controller';

describe('Refresh on form changes controller', () => {
  let ctx:StimulusTestContext;
  let RefreshOnFormChangesController:typeof RefreshOnFormChangesControllerType;
  let fetchSpy:Mock;

  beforeAll(async () => {
    ({ default: RefreshOnFormChangesController } = await import('./refresh-on-form-changes.controller'));
  });

  beforeEach(async () => {
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(turboStreamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    ctx = await setupStimulusTest({
      controllers: { 'refresh-on-form-changes': RefreshOnFormChangesController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
  });

  function turboStreamResponse(status = 200, content = 'Refreshed') {
    return new Response(
      `<turbo-stream action="update" target="sprint-dialog-form"><template>${content}</template></turbo-stream>`,
      { status, headers: { 'Content-Type': 'text/vnd.turbo-stream.html' } },
    );
  }

  const refreshedContent = () => ctx.container.querySelector('#sprint-dialog-form')?.textContent;

  async function renderForm() {
    await ctx.mount(`
      <form data-controller="refresh-on-form-changes"
            data-refresh-on-form-changes-target="form"
            data-refresh-on-form-changes-turbo-stream-url-value="/refresh">
        <input name="sprint[name]" value="Created sprint">
        <textarea name="sprint[goal][text]">Deliver the first MVP scope.</textarea>
        <div id="sprint-dialog-form"></div>
      </form>
    `);

    return ctx.getController<RefreshOnFormChangesControllerType>('refresh-on-form-changes');
  }

  it('requests a turbo stream refresh with the current form data in the POST body', async () => {
    const controller = await renderForm();

    controller.triggerTurboStream();

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalled();
    });

    const [url, init] = fetchSpy.mock.calls[0] as [string, RequestInit & { headers:Headers }];
    const parsedUrl = new URL(url, window.location.origin);

    expect(parsedUrl.pathname).toBe('/refresh');
    expect(parsedUrl.search).toBe('');

    const body = init.body as FormData;
    expect(body).toBeInstanceOf(FormData);
    expect(body.get('sprint[name]')).toBe('Created sprint');
    expect(body.get('sprint[goal][text]')).toBe('Deliver the first MVP scope.');
    expect(init.method).toBe('POST');
    expect(init.headers.get('Accept')).toBe('text/vnd.turbo-stream.html, text/html, application/xhtml+xml');
    expect(init.headers.get('X-Requested-With')).toBe('XMLHttpRequest');

    await waitFor(() => {
      expect(refreshedContent()).toBe('Refreshed');
    });
  });

  it('renders the stream of a 422 response', async () => {
    fetchSpy.mockResolvedValueOnce(turboStreamResponse(422, 'Invalid'));
    const controller = await renderForm();

    controller.triggerTurboStream();

    await waitFor(() => {
      expect(refreshedContent()).toBe('Invalid');
    });
  });

  it('logs other HTTP errors instead of rendering them', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    fetchSpy.mockResolvedValueOnce(turboStreamResponse(500, 'Broken'));
    const controller = await renderForm();

    controller.triggerTurboStream();

    await waitFor(() => {
      expect(consoleError).toHaveBeenCalledWith('Form refresh failed (HTTP 500)');
    });
    expect(refreshedContent()).toBe('');
  });

  it('drops the _method override so the refresh stays a POST', async () => {
    await ctx.mount(`
      <form data-controller="refresh-on-form-changes"
            data-refresh-on-form-changes-target="form"
            data-refresh-on-form-changes-turbo-stream-url-value="/refresh">
        <input type="hidden" name="_method" value="patch">
        <input name="sprint[name]" value="Created sprint">
      </form>
    `);
    const controller = ctx.getController<RefreshOnFormChangesControllerType>('refresh-on-form-changes');

    controller.triggerTurboStream();

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalled();
    });

    const [, init] = fetchSpy.mock.calls[0] as [string, RequestInit];
    const body = init.body as FormData;
    expect(init).toEqual(expect.objectContaining({ method: 'POST' }));
    expect(body.has('_method')).toBe(false);
    expect(body.get('sprint[name]')).toBe('Created sprint');
  });

  it('omits file inputs from the refresh body so selected files are not uploaded', async () => {
    await ctx.mount(`
      <form data-controller="refresh-on-form-changes"
            data-refresh-on-form-changes-target="form"
            data-refresh-on-form-changes-turbo-stream-url-value="/refresh">
        <input name="sprint[name]" value="Created sprint">
        <input type="file" name="sprint[attachment]">
      </form>
    `);
    const controller = ctx.getController<RefreshOnFormChangesControllerType>('refresh-on-form-changes');
    const fileInput = ctx.container.querySelector<HTMLInputElement>('[name="sprint[attachment]"]')!;
    const file = new File(['secret contents'], 'secret.txt', { type: 'text/plain' });
    const transfer = new DataTransfer();
    transfer.items.add(file);
    fileInput.files = transfer.files;

    controller.triggerTurboStream();

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalled();
    });

    const [, init] = fetchSpy.mock.calls[0] as [string, RequestInit];
    const body = init.body as FormData;
    expect(body.has('sprint[attachment]')).toBe(false);
    expect(body.get('sprint[name]')).toBe('Created sprint');
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
      expect(refreshedContent()).toBe('Refreshed');
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
    const [, init] = fetchSpy.mock.calls[0] as [string, RequestInit];
    expect((init.body as FormData).get('sprint[goal][text]')).toBe('Updated goal');
  });

  it('dispatches beforeSnapshot before reading the form, so late edits are captured', async () => {
    const controller = await renderForm();
    const form = ctx.container.querySelector('form')!;
    const goal = ctx.container.querySelector<HTMLTextAreaElement>('[name="sprint[goal][text]"]')!;

    // Stand in for CKEditor flushing its latest content into the textarea on the event.
    form.addEventListener('refresh-on-form-changes:beforeSnapshot', () => {
      goal.value = 'Flushed just before snapshot';
    });

    controller.triggerTurboStream();

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalled();
    });

    const [, init] = fetchSpy.mock.calls[0] as [string, RequestInit];
    expect((init.body as FormData).get('sprint[goal][text]')).toBe('Flushed just before snapshot');
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
