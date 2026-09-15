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
import type RequirePasswordConfirmationControllerType from './require-password-confirmation.controller';

const STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html; charset=utf-8';
const NEGOTIATED_ACCEPT = 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml';
const STREAM_HTML = '<turbo-stream action="append" target="stream-target"><template><span class="chunk"></span></template></turbo-stream>';

function streamResponse():Response {
  return new Response(STREAM_HTML, { status: 200, headers: { 'Content-Type': STREAM_CONTENT_TYPE } });
}

function htmlResponse():Response {
  return new Response('<p>Login</p>', { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}

describe('Require password confirmation controller', () => {
  let ctx:StimulusTestContext;
  let RequirePasswordConfirmationController:typeof RequirePasswordConfirmationControllerType;
  let myPasswordConfirmationDialogPath:Mock;
  let fetchSpy:Mock;
  let target:HTMLElement;
  let originalOpenProject:typeof window.OpenProject;

  beforeAll(async () => {
    ({ default: RequirePasswordConfirmationController } = await import('./require-password-confirmation.controller'));
  });

  beforeEach(async () => {
    myPasswordConfirmationDialogPath = vi.fn().mockReturnValue('/my/password_confirmation_dialog');
    fetchSpy = vi.fn().mockImplementation(() => Promise.resolve(streamResponse()));
    vi.spyOn(window, 'fetch').mockImplementation(fetchSpy);

    target = document.createElement('div');
    target.id = 'stream-target';
    document.body.appendChild(target);

    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({
        services: { pathHelperService: { myPasswordConfirmationDialogPath } },
      }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({
      controllers: { 'require-password-confirmation': RequirePasswordConfirmationController },
    });
  });

  const flush = () => new Promise((resolve) => { setTimeout(resolve, 20); });

  afterEach(async () => {
    await flush();
    ctx.dispose();
    target.remove();
    window.OpenProject = originalOpenProject;
    vi.restoreAllMocks();
  });

  const renderedChunks = () => target.querySelectorAll('.chunk').length;

  async function renderForm() {
    await ctx.mount(`
      <form data-controller="require-password-confirmation" action="/my/account" method="post">
        <button type="submit">Save</button>
      </form>
    `);
    return ctx.container.querySelector('form')!;
  }

  function submit(form:HTMLFormElement):SubmitEvent {
    const event = new SubmitEvent('submit', { cancelable: true, bubbles: true });
    form.dispatchEvent(event);
    return event;
  }

  it('binds the declared services after connect', async () => {
    await renderForm();
    const controller = ctx.getController<RequirePasswordConfirmationControllerType>('require-password-confirmation');

    await expect(controller.services).resolves.toMatchObject({
      pathHelperService: { myPasswordConfirmationDialogPath },
    });
  });

  it('intercepts the submit and requests the confirmation dialog', async () => {
    const form = await renderForm();

    const event = submit(form);

    expect(event.defaultPrevented).toBe(true);

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledWith(
        '/my/password_confirmation_dialog',
        expect.objectContaining({ method: 'GET' }),
      );
    });
  });

  it('intercepts submit in the capture phase before bubble listeners', async () => {
    const form = await renderForm();
    const bubbleOrder:string[] = [];

    form.addEventListener('submit', (event) => {
      bubbleOrder.push(`bubble:prevented=${event.defaultPrevented}`);
    });

    const event = submit(form);

    expect(event.defaultPrevented).toBe(true);
    expect(bubbleOrder).toEqual(['bubble:prevented=true']);
  });

  it('appends the confirmed password and resubmits the form', async () => {
    const form = await renderForm();
    const requestSubmit = vi.fn();
    form.requestSubmit = requestSubmit;

    submit(form);
    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalled();
    });

    document.dispatchEvent(new CustomEvent('password-confirmation-dialog:submit', { detail: 'secret' }));

    const input = form.querySelector<HTMLInputElement>('#hidden_password_confirmation')!;
    expect(input.value).toBe('secret');
    expect(input.name).toBe('_password_confirmation');
    expect(requestSubmit).toHaveBeenCalled();
  });

  it('reopens the dialog after a cancelled confirmation', async () => {
    const form = await renderForm();

    submit(form);
    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });

    // Primer/Turbo removes the dialog during `close`, then dispatches dialog:close.
    const dialog = document.createElement('dialog');
    dialog.id = 'password-confirmation-dialog';
    document.dispatchEvent(new CustomEvent('dialog:close', { detail: { dialog, submitted: false } }));

    fetchSpy.mockClear();
    submit(form);

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });
  });

  it('ignores dialog:close events for other dialogs', async () => {
    const form = await renderForm();

    submit(form);
    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });

    const other = document.createElement('dialog');
    other.id = 'some-other-dialog';
    document.dispatchEvent(new CustomEvent('dialog:close', { detail: { dialog: other, submitted: false } }));

    fetchSpy.mockClear();
    submit(form);

    await ctx.nextFrame();
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('intercepts submits arriving before the plugin context resolves', async () => {
    let resolveContext!:(context:unknown) => void;
    window.OpenProject = {
      getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
    } as unknown as typeof window.OpenProject;

    const form = await renderForm();

    const event = submit(form);

    expect(event.defaultPrevented).toBe(true);

    form.remove();
    await ctx.nextFrame();

    resolveContext({
      services: { pathHelperService: { myPasswordConfirmationDialogPath } },
    });
    await ctx.nextFrame();

    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('renders the confirmation dialog stream', async () => {
    const form = await renderForm();

    submit(form);

    await waitFor(() => { expect(renderedChunks()).toBe(1); });
    const [, init] = fetchSpy.mock.lastCall as [string, RequestInit & { headers:Headers }];
    expect(init.headers.get('Accept')).toBe(NEGOTIATED_ACCEPT);
    expect(init.headers.has('X-CSRF-Token')).toBe(false);
  });

  it.each([
    ['a non-stream response', () => Promise.resolve(htmlResponse())],
    ['a failed request', () => Promise.reject(new TypeError('Failed to fetch'))],
  ])('allows a new dialog request after %s', async (_label, outcome) => {
    fetchSpy.mockImplementationOnce(outcome);
    const form = await renderForm();

    submit(form);
    await waitFor(() => { expect(fetchSpy).toHaveBeenCalledTimes(1); });
    expect(renderedChunks()).toBe(0);

    // activeDialog is released asynchronously in the catch; resubmitting
    // until the second request goes out avoids a fixed sleep.
    await waitFor(() => {
      submit(form);
      expect(fetchSpy).toHaveBeenCalledTimes(2);
    });
  });
});
