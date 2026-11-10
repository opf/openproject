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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import type { FetchResponse } from '@rails/request.js';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { vi, type Mock } from 'vitest';

import type { IToast } from 'core-app/shared/components/toaster/toast.service';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import { TurboHelpers } from 'core-turbo/helpers';
import type AsyncDialogControllerType from './async-dialog.controller';

const perform = vi.fn();
const FetchRequest = vi.fn(function FetchRequestMock(
  _method:string,
  _url:string|URL,
  _options:{ body?:FormData; responseKind:'turbo-stream' },
) {
  return { perform };
});

vi.doMock('@rails/request.js', () => ({ FetchRequest }));

describe('Async dialog controller', () => {
  let ctx:StimulusTestContext;
  let AsyncDialogController:typeof AsyncDialogControllerType;
  let showProgressBar:Mock;
  let hideProgressBar:Mock;
  let toasts:IToast[];
  const onToast = (event:Event) => toasts.push((event as CustomEvent<IToast>).detail);

  beforeAll(async () => {
    ({ default: AsyncDialogController } = await import('./async-dialog.controller'));
  });

  beforeEach(async () => {
    FetchRequest.mockClear();
    perform.mockReset();
    toasts = [];
    window.addEventListener('op:toasters:add', onToast);
    showProgressBar = vi.spyOn(TurboHelpers, 'showProgressBar').mockImplementation(() => undefined);
    hideProgressBar = vi.spyOn(TurboHelpers, 'hideProgressBar').mockImplementation(() => undefined);

    ctx = await setupStimulusTest({
      controllers: { 'async-dialog': AsyncDialogController },
    });
  });

  afterEach(() => {
    window.removeEventListener('op:toasters:add', onToast);
    ctx.dispose();
    vi.restoreAllMocks();
  });

  function turboStreamResponse({
    ok = true,
    unprocessableEntity = false,
  }:{ ok?:boolean; unprocessableEntity?:boolean } = {}) {
    const renderTurboStream = vi.fn().mockResolvedValue(undefined);
    const response = {
      ok,
      unprocessableEntity,
      isTurboStream: true,
      renderTurboStream,
    } as unknown as FetchResponse;
    return { response, renderTurboStream };
  }

  function nonTurboResponse() {
    const renderTurboStream = vi.fn().mockResolvedValue(undefined);
    const response = {
      ok: true,
      unprocessableEntity: false,
      isTurboStream: false,
      renderTurboStream,
    } as unknown as FetchResponse;
    return { response, renderTurboStream };
  }

  function resolveLikeFetchRequest(response:FetchResponse) {
    perform.mockImplementation(async () => {
      if ((response.ok || response.unprocessableEntity) && response.isTurboStream) {
        await response.renderTurboStream();
      }

      return response;
    });
  }

  async function mountPostButton() {
    await ctx.mount(`
      <form id="dialog-form" method="post" action="/dialog">
        <input type="hidden" name="authenticity_token" value="token">
        <button type="button" form="dialog-form" data-controller="async-dialog">Open</button>
      </form>
    `);

    const form = ctx.container.querySelector<HTMLFormElement>('#dialog-form')!;
    const button = within(ctx.container).getByRole('button', { name: 'Open' });
    Object.defineProperty(form, 'action', { configurable: true, value: '/dialog' });
    return { button, form };
  }

  function trigger(controller:AsyncDialogControllerType, url?:string) {
    return (controller as unknown as { triggerTurboStream(url?:string):Promise<void> }).triggerTurboStream(url);
  }

  it('dispatches beforeLoad and submits form data captured after synchronous listeners run', async () => {
    const { response } = turboStreamResponse();
    resolveLikeFetchRequest(response);
    const { button, form } = await mountPostButton();
    let beforeLoad!:CustomEvent<{ form:HTMLFormElement|null }>;
    button.addEventListener('async-dialog:beforeLoad', (event) => {
      beforeLoad = event as CustomEvent<{ form:HTMLFormElement|null }>;
      const input = document.createElement('input');
      input.name = 'ids[]';
      input.value = '7';
      form.appendChild(input);
    });

    fireEvent.click(button);

    await waitFor(() => expect(FetchRequest).toHaveBeenCalledOnce());
    expect(beforeLoad.defaultPrevented).toBe(false);
    expect(beforeLoad.detail.form).toBe(form);
    const [, , options] = FetchRequest.mock.calls[0];
    const submitted = options.body;
    expect(submitted).toBeInstanceOf(FormData);
    expect(FetchRequest).toHaveBeenCalledWith('post', '/dialog', {
      body: submitted,
      responseKind: 'turbo-stream',
    });
    if (!(submitted instanceof FormData)) throw new Error('Expected form data');
    expect([...submitted.entries()]).toEqual([['authenticity_token', 'token'], ['ids[]', '7']]);
  });

  it('submits the action and method updated by a beforeLoad listener', async () => {
    resolveLikeFetchRequest(turboStreamResponse().response);
    const { button, form } = await mountPostButton();
    Reflect.deleteProperty(form, 'action');
    button.addEventListener('async-dialog:beforeLoad', () => {
      form.action = '/retargeted-dialog';
      form.method = 'get';
    });

    fireEvent.click(button);

    await waitFor(() => expect(FetchRequest).toHaveBeenCalledOnce());
    expect(FetchRequest).toHaveBeenCalledWith('get', new URL('/retargeted-dialog', window.location.href).href, {
      body: expect.any(FormData),
      responseKind: 'turbo-stream',
    });
  });

  it('makes no request when beforeLoad is canceled', async () => {
    const { button } = await mountPostButton();
    button.addEventListener('async-dialog:beforeLoad', (event) => event.preventDefault());

    fireEvent.click(button);
    await ctx.nextFrame();

    expect(FetchRequest).not.toHaveBeenCalled();
    expect(showProgressBar).not.toHaveBeenCalled();
  });

  it('does not request an unresolved URL after a form button loses its associated form', async () => {
    resolveLikeFetchRequest(turboStreamResponse().response);
    const { button, form } = await mountPostButton();
    const controller = ctx.application.getControllerForElementAndIdentifier(button, 'async-dialog') as AsyncDialogControllerType;
    const beforeLoad = vi.fn();
    button.addEventListener('async-dialog:beforeLoad', beforeLoad);
    form.removeAttribute('id');
    expect(controller.href).toBeUndefined();

    await trigger(controller);

    expect(beforeLoad).not.toHaveBeenCalled();

    expect(FetchRequest).not.toHaveBeenCalled();
    expect(showProgressBar).not.toHaveBeenCalled();
    expect(button).not.toHaveAttribute('aria-disabled');
  });

  it('does not request an empty custom URL', async () => {
    resolveLikeFetchRequest(turboStreamResponse().response);
    const { button } = await mountPostButton();
    const controller = ctx.application.getControllerForElementAndIdentifier(button, 'async-dialog') as AsyncDialogControllerType;

    const beforeLoad = vi.fn();
    button.addEventListener('async-dialog:beforeLoad', beforeLoad);

    await trigger(controller, '');

    expect(beforeLoad).not.toHaveBeenCalled();

    expect(FetchRequest).not.toHaveBeenCalled();
    expect(showProgressBar).not.toHaveBeenCalled();
  });

  it('keeps existing anchors on GET with their href', async () => {
    const { response } = turboStreamResponse();
    resolveLikeFetchRequest(response);
    await ctx.mount('<a href="/dialog" data-controller="async-dialog">Open</a>');
    const anchor = within(ctx.container).getByRole<HTMLAnchorElement>('link', { name: 'Open' });

    fireEvent.click(anchor);

    await waitFor(() => expect(FetchRequest).toHaveBeenCalledOnce());
    expect(FetchRequest).toHaveBeenCalledWith('GET', anchor.href, {
      body: undefined,
      responseKind: 'turbo-stream',
    });
  });

  it('ignores repeated activation while a request is loading', async () => {
    let resolveRequest!:(response:FetchResponse) => void;
    perform.mockReturnValue(new Promise((resolve) => { resolveRequest = resolve; }));
    const { button } = await mountPostButton();

    fireEvent.click(button);
    fireEvent.click(button);

    expect(FetchRequest).toHaveBeenCalledOnce();
    resolveRequest(turboStreamResponse().response);
    await waitFor(() => expect(button).not.toHaveAttribute('aria-disabled'));
  });

  it.each([
    ['a successful response', turboStreamResponse().response],
    ['an unprocessable response', turboStreamResponse({ ok: false, unprocessableEntity: true }).response],
  ])('clears loading state after %s', async (_label, response) => {
    resolveLikeFetchRequest(response);
    const { button } = await mountPostButton();

    fireEvent.click(button);
    expect(button).toHaveAttribute('aria-disabled', 'true');

    await waitFor(() => expect(button).not.toHaveAttribute('aria-disabled'));
    expect(showProgressBar).toHaveBeenCalledOnce();
    expect(hideProgressBar).toHaveBeenCalledOnce();
  });

  it('renders a 500 Turbo Stream exactly once and clears loading state', async () => {
    const { response, renderTurboStream } = turboStreamResponse({ ok: false });
    resolveLikeFetchRequest(response);
    const { button } = await mountPostButton();

    fireEvent.click(button);

    await waitFor(() => expect(renderTurboStream).toHaveBeenCalledOnce());
    expect(button).not.toHaveAttribute('aria-disabled');
    expect(hideProgressBar).toHaveBeenCalledOnce();
    expect(toasts).toEqual([]);
  });

  it('shows an error toast for a 200 non-Turbo response and clears loading state', async () => {
    const { response, renderTurboStream } = nonTurboResponse();
    resolveLikeFetchRequest(response);
    const { button } = await mountPostButton();
    const controller = ctx.getController<AsyncDialogControllerType>('async-dialog', button);

    await trigger(controller);

    expect(toasts).toEqual([{ type: 'error', message: I18n.t('js.error.internal') }]);
    expect(renderTurboStream).not.toHaveBeenCalled();
    expect(button).not.toHaveAttribute('aria-disabled');
    expect(hideProgressBar).toHaveBeenCalledOnce();
  });

  it('shows an error toast and clears loading state when the request rejects', async () => {
    perform.mockRejectedValue(new Error('network failed'));
    const { button } = await mountPostButton();
    const controller = ctx.getController<AsyncDialogControllerType>('async-dialog', button);

    await trigger(controller);

    expect(toasts).toEqual([{ type: 'error', message: I18n.t('js.error.internal') }]);
    expect(button).not.toHaveAttribute('aria-disabled');
    expect(hideProgressBar).toHaveBeenCalledOnce();
  });

  it('uses a custom event URL without including the associated form', async () => {
    const { response } = turboStreamResponse();
    resolveLikeFetchRequest(response);
    const { button } = await mountPostButton();
    const controller = ctx.getController<AsyncDialogControllerType>('async-dialog', button);
    let associatedForm:HTMLFormElement|null|undefined;
    button.addEventListener('async-dialog:beforeLoad', (event) => {
      associatedForm = (event as CustomEvent<{ form:HTMLFormElement|null }>).detail.form;
    });

    controller.handleOpenDialog(new CustomEvent('open', { detail: { url: '/override' } }));

    await waitFor(() => expect(FetchRequest).toHaveBeenCalledOnce());
    expect(associatedForm).toBeNull();
    expect(FetchRequest).toHaveBeenCalledWith('GET', '/override', {
      body: undefined,
      responseKind: 'turbo-stream',
    });
  });
});
