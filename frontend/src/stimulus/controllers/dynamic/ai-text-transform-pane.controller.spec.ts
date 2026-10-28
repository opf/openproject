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

import { fireEvent } from '@testing-library/dom';
import type { Mock, MockInstance } from 'vitest';
import type { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import AiTextTransformPaneController from './ai-text-transform-pane.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('AiTextTransformPaneController', () => {
  let ctx:StimulusTestContext;
  let originalOpenProject:typeof window.OpenProject;
  let turboRequests:{ request:Mock<TurboRequestsService['request']> };

  const CLOSE_FORM_ID = 'ai-text-transform-pane-close';
  const action = (event:string, name:string) => `data-action="${event}->ai-text-transform-pane#${name}"`;

  const HTML = `
<div data-controller="ai-text-transform-pane"
     data-ai-text-transform-pane-close-form-value="${CLOSE_FORM_ID}"
     data-action="keydown.esc->ai-text-transform-pane#close resize@window->ai-text-transform-pane#keepInViewport turbo:submit-end->ai-text-transform-pane#submitEnded turbo:submit-start->ai-text-transform-pane#submitStarted">
  <div data-ai-text-transform-pane-target="pane" role="dialog" aria-label="AI result" tabindex="-1"
       style="position: fixed; top: 40px; right: 16px; width: 340px; height: 260px; max-width: calc(100vw - 32px);">
    <div data-testid="header" ${action('pointerdown', 'beginDrag')}>
      <a href="#">Link</a>
      <button type="button" aria-label="Close" ${action('click', 'close')}>×</button>
    </div>
    <div>
      <span data-testid="grip" ${action('pointerdown', 'beginDrag')}></span>
    </div>
    <span data-testid="resize-left" data-edge="left" ${action('pointerdown', 'beginResize')}></span>
    <span data-testid="resize-bottom-right" data-edge="bottom-right" ${action('pointerdown', 'beginResize')}></span>
  </div>
</div>`;

  const wrapper = () => ctx.container.querySelector<HTMLElement>('[data-controller="ai-text-transform-pane"]');
  const pane = () => ctx.screen.getByRole('dialog', { name: 'AI result' });
  const closeButton = () => ctx.screen.getByRole('button', { name: 'Close' });
  const link = () => ctx.screen.getByRole('link', { name: 'Link' });
  const rect = () => pane().getBoundingClientRect().toJSON() as DOMRect;
  const byTestId = (id:string) => ctx.screen.getByTestId(id);

  function dragBy(handle:HTMLElement, dx:number, dy:number, button = 0):void {
    const start = handle.getBoundingClientRect();
    const end = { clientX: start.left + dx, clientY: start.top + dy };
    fireEvent.pointerDown(handle, { clientX: start.left, clientY: start.top, button });
    fireEvent.pointerMove(window, end);
    fireEvent.pointerUp(window, end);
  }

  function pressEscape():void {
    fireEvent.keyDown(pane(), { key: 'Escape' });
  }

  beforeEach(async () => {
    turboRequests = { request: vi.fn<TurboRequestsService['request']>().mockResolvedValue({ html: '', headers: new Headers() }) };
    originalOpenProject = window.OpenProject;
    window.OpenProject = {
      getPluginContext: () => Promise.resolve({ services: { turboRequests } }),
    } as unknown as typeof window.OpenProject;

    ctx = await setupStimulusTest({ controllers: { 'ai-text-transform-pane': AiTextTransformPaneController } });
    await ctx.mount(HTML);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
    window.OpenProject = originalOpenProject;
    // Unpinning before the controller disconnects keeps the remembered geometry from leaking into the next test.
    ctx.container.querySelector('[data-ai-text-transform-pane-target="pane"]')?.removeAttribute('style');
    ctx.dispose();
  });

  it('focuses the pane on connect', () => {
    expect(pane()).toHaveFocus();
  });

  describe('dragging', () => {
    it('moves the pane by the header and pins it with left and top', () => {
      const before = rect();
      dragBy(byTestId('header'), -20, 30);

      expect(pane()).toHaveStyle({ left: `${before.left - 20}px`, top: `${before.top + 30}px` });
      expect(pane().style.right).toBe('auto');
      expect(pane().style.bottom).toBe('auto');
    });

    it('moves the pane by the footer grip', () => {
      const before = rect();
      dragBy(byTestId('grip'), -10, 10);

      expect(rect().left).toBe(before.left - 10);
      expect(rect().top).toBe(before.top + 10);
    });

    it('does not start a drag on interactive elements in the header', () => {
      const before = rect();
      dragBy(closeButton(), -20, 30);
      dragBy(link(), -20, 30);

      expect(rect()).toEqual(before);
    });

    it('does not start a drag with a secondary button', () => {
      const before = rect();
      dragBy(byTestId('header'), -20, 30, 2);

      expect(rect()).toEqual(before);
    });

    it('keeps the pane inside the viewport', () => {
      dragBy(byTestId('header'), -5000, -5000);
      expect(pane()).toHaveStyle({ left: '8px', top: '8px' });

      dragBy(byTestId('header'), 5000, 5000);
      expect(rect().right).toBe(window.innerWidth - 8);
      expect(rect().bottom).toBe(window.innerHeight - 8);
    });

    it('stops following the pointer after pointerup', () => {
      dragBy(byTestId('header'), -20, 30);
      const after = rect();
      fireEvent.pointerMove(window, { clientX: 0, clientY: 0 });

      expect(rect()).toEqual(after);
    });

    it('stops following the pointer after pointercancel', () => {
      const header = byTestId('header');
      const start = header.getBoundingClientRect();
      const before = rect();
      fireEvent.pointerDown(header, { clientX: start.left, clientY: start.top });
      fireEvent.pointerCancel(window, { clientX: start.left, clientY: start.top });
      fireEvent.pointerMove(window, { clientX: start.left - 20, clientY: start.top + 30 });

      expect(rect()).toEqual(before);
    });

    it('stops the previous pointer action when a new one starts', () => {
      const before = rect();
      const header = byTestId('header').getBoundingClientRect();
      const handle = byTestId('resize-bottom-right');
      const start = handle.getBoundingClientRect();
      fireEvent.pointerDown(byTestId('header'), { clientX: header.left, clientY: header.top });
      fireEvent.pointerDown(handle, { clientX: start.left, clientY: start.top });
      fireEvent.pointerMove(window, { clientX: start.left - 10, clientY: start.top - 10 });
      fireEvent.pointerUp(window);

      expect(rect().left).toBe(before.left);
      expect(rect().width).toBe(before.width - 10);
    });
  });

  describe('resizing', () => {
    it('clamps the bottom-right handle to the minimum size and the viewport', () => {
      const handle = byTestId('resize-bottom-right');
      dragBy(handle, -5000, -5000);
      expect(rect().width).toBe(320);
      expect(rect().height).toBe(240);

      dragBy(handle, 5000, 5000);
      expect(rect().right).toBe(window.innerWidth - 8);
      expect(rect().bottom).toBe(window.innerHeight - 8);
    });

    it('moves only the left edge with the left handle', () => {
      const before = rect();
      dragBy(byTestId('resize-left'), -30, 0);

      expect(rect().left).toBe(before.left - 30);
      expect(rect().width).toBe(before.width + 30);
      expect(rect().right).toBe(before.right);
      expect(rect().height).toBe(before.height);
    });

    it('keeps the right edge when the left handle grows past the stylesheet max-width', () => {
      const before = rect();
      dragBy(byTestId('resize-left'), -5000, 0);

      expect(rect().left).toBe(8);
      expect(rect().right).toBe(before.right);
    });
  });

  describe('geometry', () => {
    it('is restored when the pane is replaced', async () => {
      dragBy(byTestId('header'), -20, 30);
      dragBy(byTestId('resize-bottom-right'), -10, 10);
      const geometry = rect();

      wrapper()!.remove();
      await ctx.mount(HTML);

      expect(rect()).toEqual(geometry);
    });

    it('is brought back into the viewport when restored', async () => {
      dragBy(byTestId('header'), -20, 30);
      pane().style.left = '5000px';

      wrapper()!.remove();
      await ctx.mount(HTML);

      expect(rect().right).toBe(window.innerWidth - 8);
    });

    it('is brought back into the viewport when the window resizes', () => {
      dragBy(byTestId('header'), -20, 30);
      pane().style.left = '5000px';

      fireEvent.resize(window);

      expect(rect().right).toBe(window.innerWidth - 8);
    });

    it('keeps a resized pane inside the viewport when the window shrinks', () => {
      dragBy(byTestId('resize-bottom-right'), 10, 10);
      pane().style.width = `${window.innerWidth * 2}px`;
      pane().style.height = `${window.innerHeight * 2}px`;

      fireEvent.resize(window);

      expect(rect().left).toBe(8);
      expect(rect().right).toBe(window.innerWidth - 8);
      expect(rect().bottom).toBe(window.innerHeight - 8);
    });
  });

  describe('closing', () => {
    it('submits the close form on Escape when it exists', () => {
      ctx.appendHTML(`<form id="${CLOSE_FORM_ID}"></form>`);
      const form = document.getElementById(CLOSE_FORM_ID) as HTMLFormElement;
      const submit = vi.spyOn(form, 'requestSubmit').mockImplementation(() => undefined);

      pressEscape();

      expect(submit).toHaveBeenCalled();
      expect(pane()).toBeInTheDocument();
    });

    describe('when a form in the pane finishes its request', () => {
      function submitEnd(formId:string, detail:{ success?:boolean }):void {
        pane().insertAdjacentHTML('beforeend', `<form id="${formId}"></form>`);
        const form = document.getElementById(formId) as HTMLFormElement;
        form.dispatchEvent(new CustomEvent('turbo:submit-end', { bubbles: true, detail }));
      }

      it('keeps the pane when the close request succeeds', () => {
        submitEnd(CLOSE_FORM_ID, { success: true });

        expect(pane()).toBeInTheDocument();
      });

      it('keeps the pane when the close request was aborted by a newer one', () => {
        submitEnd(CLOSE_FORM_ID, {});

        expect(pane()).toBeInTheDocument();
      });

      it('removes the pane when the close request fails', () => {
        const removedPane = pane();
        submitEnd(CLOSE_FORM_ID, { success: false });

        expect(removedPane).not.toBeInTheDocument();
      });

      it('keeps the pane when another form fails', () => {
        submitEnd('ai-text-transform-pane-apply', { success: false });

        expect(pane()).toBeInTheDocument();
      });
    });

    it('does not let Escape reach surrounding dialogs', () => {
      const outerListener = vi.fn();
      ctx.container.addEventListener('keydown', outerListener);
      pressEscape();

      expect(outerListener).not.toHaveBeenCalled();
    });

    it('removes the pane on Escape without a close form', () => {
      const removedPane = pane();
      pressEscape();

      expect(removedPane).not.toBeInTheDocument();
    });

    it('removes the pane with the header close button', () => {
      const removedPane = pane();
      fireEvent.click(closeButton());

      expect(removedPane).not.toBeInTheDocument();
    });
  });
  describe('running', () => {
    const RUN = '9b2f6a8e-1c5d-4e7f-8a9b-0c1d2e3f4a5b';
    const REQUEST_ID = '5f0c1b9a-2d3e-4f50-8a6b-7c8d9e0f1a2b';
    const APPLY_FORM_ID = 'ai-text-transform-pane-apply';
    const POLL_URL = `/ai/text_transform_panes/${RUN}?request_id=${REQUEST_ID}&scope=document`;

    const errorBanner = () => ctx.screen.getByTestId('error-banner');
    const button = (name:string) => ctx.screen.getByRole('button', { name });

    function renderFooter(state:string, seq = 1):void {
      const buttons = state === 'generating'
        ? `<button type="submit" form="${CLOSE_FORM_ID}">Cancel</button>`
        : `<button type="submit" form="${CLOSE_FORM_ID}">Discard</button>
           <button type="submit" form="${APPLY_FORM_ID}">Replace</button>`;
      footer().innerHTML = `
        <span hidden data-ai-text-transform-pane-target="state" data-state="${state}" data-run="${RUN}"
              data-seq="${seq}" data-request-id="${REQUEST_ID}" data-poll-url="${POLL_URL}"></span>
        <form id="${CLOSE_FORM_ID}"></form>
        <form id="${APPLY_FORM_ID}"></form>
        ${buttons}`;
    }

    function footer():HTMLElement {
      return pane().querySelector<HTMLElement>('#footer')!;
    }

    async function mountRun(state:string, seq = 1):Promise<void> {
      pane().insertAdjacentHTML('beforeend', `
        <div data-testid="error-banner" hidden data-ai-text-transform-pane-target="error">
          <span data-ai-text-transform-pane-target="errorMessage"></span>
        </div>
        <div id="footer"></div>`);
      renderFooter(state, seq);
      await ctx.nextFrame();
    }

    async function settle():Promise<void> {
      await vi.advanceTimersByTimeAsync(0);
      await ctx.nextFrame();
    }

    function polledUrls():URL[] {
      return turboRequests.request.mock.calls.map(([url]) => new URL(url, window.location.origin));
    }

    function submit(eventName:string, formId:string, detail:object = {}):void {
      document.getElementById(formId)!.dispatchEvent(new CustomEvent(eventName, { bubbles: true, detail }));
    }

    function dispatchAccepted(requestId = REQUEST_ID):void {
      document.dispatchEvent(new CustomEvent('op-dispatched:ai-text-transform:accepted', { detail: { requestId } }));
    }

    function dispatchApplied(ok:boolean, requestId = REQUEST_ID):void {
      window.dispatchEvent(new CustomEvent('op:ai-text-transform:applied', { detail: { requestId, ok } }));
    }

    beforeEach(() => {
      vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
      const element = wrapper()!;
      element.dataset.aiTextTransformPaneEditorGoneValue = 'Editor gone';
      element.dataset.aiTextTransformPaneSelectionGoneValue = 'Selection gone';
      element.dataset.aiTextTransformPaneRequestFailedValue = 'Request failed';
      element.dataset.action += [
        ' op-dispatched:ai-text-transform:accepted@document->ai-text-transform-pane#accepted',
        'op:ai-text-transform:applied@window->ai-text-transform-pane#applied',
        'pagehide@window->ai-text-transform-pane#abandon',
        'turbo:before-stream-render@document->ai-text-transform-pane#rememberFocus',
      ].join(' ');
    });

    describe('polling', () => {
      it('asks for news after the last event and state it has seen', async () => {
        await mountRun('generating', 3);
        await vi.advanceTimersByTimeAsync(399);
        expect(turboRequests.request).not.toHaveBeenCalled();

        await vi.advanceTimersByTimeAsync(1);

        const [url, init, suppressErrorToast] = turboRequests.request.mock.calls[0];
        expect(new URL(url).pathname).toBe(`/ai/text_transform_panes/${RUN}`);
        expect(Object.fromEntries(new URL(url).searchParams))
          .toEqual({ request_id: REQUEST_ID, scope: 'document', after: '3', state: 'generating' });
        expect(init).toMatchObject({ method: 'GET', headers: { Accept: 'text/vnd.turbo-stream.html' } });
        expect(suppressErrorToast).toBe(true);
      });

      it('backs off while nothing changes, up to one second', async () => {
        await mountRun('generating');

        for (const delay of [400, 600, 900, 1000, 1000]) {
          const calls = turboRequests.request.mock.calls.length;
          await vi.advanceTimersByTimeAsync(delay - 1);
          expect(turboRequests.request).toHaveBeenCalledTimes(calls);
          await vi.advanceTimersByTimeAsync(1);
          expect(turboRequests.request).toHaveBeenCalledTimes(calls + 1);
        }
      });

      it('polls quickly again after news and reads the replaced state element', async () => {
        turboRequests.request.mockImplementationOnce(() => {
          renderFooter('generating', 5);
          return Promise.resolve({ html: '<turbo-stream></turbo-stream>', headers: new Headers() });
        });
        await mountRun('generating');

        await vi.advanceTimersByTimeAsync(400);
        await settle();
        await vi.advanceTimersByTimeAsync(400);

        expect(turboRequests.request).toHaveBeenCalledTimes(2);
        expect(polledUrls()[1].searchParams.get('after')).toBe('5');
      });

      it('polls every five seconds while the page is hidden', async () => {
        vi.spyOn(document, 'hidden', 'get').mockReturnValue(true);
        await mountRun('generating');

        await vi.advanceTimersByTimeAsync(4999);
        expect(turboRequests.request).not.toHaveBeenCalled();
        await vi.advanceTimersByTimeAsync(1);
        expect(turboRequests.request).toHaveBeenCalledTimes(1);
      });

      it('never polls a finished pane', async () => {
        await mountRun('done');

        await vi.advanceTimersByTimeAsync(10000);

        expect(turboRequests.request).not.toHaveBeenCalled();
      });

      it('stops once the run is no longer generating', async () => {
        turboRequests.request.mockImplementationOnce(() => {
          renderFooter('done', 2);
          return Promise.resolve({ html: '<turbo-stream></turbo-stream>', headers: new Headers() });
        });
        await mountRun('generating');

        await vi.advanceTimersByTimeAsync(400);
        await settle();
        await vi.advanceTimersByTimeAsync(10000);

        expect(turboRequests.request).toHaveBeenCalledTimes(1);
      });

      it('does not start a second poll while one is in flight', async () => {
        let answer:(value:{ html:string, headers:Headers }) => void = () => undefined;
        turboRequests.request.mockImplementationOnce(() => new Promise((resolve) => { answer = resolve; }));
        await mountRun('generating');

        await vi.advanceTimersByTimeAsync(400);
        renderFooter('generating', 2);
        await settle();
        await vi.advanceTimersByTimeAsync(2000);
        expect(turboRequests.request).toHaveBeenCalledTimes(1);

        answer({ html: '', headers: new Headers() });
        await vi.advanceTimersByTimeAsync(600);
        expect(turboRequests.request).toHaveBeenCalledTimes(2);
      });

      it('stops and shows the error banner when a poll fails', async () => {
        turboRequests.request.mockRejectedValueOnce(new Error('404'));
        await mountRun('generating');

        await vi.advanceTimersByTimeAsync(400);
        await vi.advanceTimersByTimeAsync(10000);

        expect(turboRequests.request).toHaveBeenCalledTimes(1);
        expect(errorBanner()).toBeVisible();
        expect(errorBanner()).toHaveTextContent('Request failed');
      });
    });

    describe('submitting', () => {
      it('disables Replace while its request is in flight and for good once it succeeded', async () => {
        await mountRun('done');

        submit('turbo:submit-start', APPLY_FORM_ID);
        expect(button('Replace')).toBeDisabled();

        submit('turbo:submit-end', APPLY_FORM_ID, { success: true });
        expect(button('Replace')).toBeDisabled();
      });

      it('enables Replace again and shows the error banner when its request fails', async () => {
        await mountRun('done');

        submit('turbo:submit-start', APPLY_FORM_ID);
        submit('turbo:submit-end', APPLY_FORM_ID, { success: false });

        expect(button('Replace')).toBeEnabled();
        expect(errorBanner()).toHaveTextContent('Request failed');
      });
    });

    describe('waiting for the editor after Replace', () => {
      beforeEach(async () => {
        await mountRun('done');
      });

      it('removes the pane once the editor applied the text', () => {
        const removedPane = pane();
        dispatchAccepted();
        dispatchApplied(true);

        expect(removedPane).not.toBeInTheDocument();
      });

      it('tells the user when the selection is gone', async () => {
        dispatchAccepted();
        dispatchApplied(false);
        await vi.advanceTimersByTimeAsync(1000);

        expect(errorBanner()).toHaveTextContent('Selection gone');
      });

      it('keeps the editor answer when it arrives before the pane saw the event', async () => {
        dispatchApplied(false);
        dispatchAccepted();
        await vi.advanceTimersByTimeAsync(1000);

        expect(errorBanner()).toHaveTextContent('Selection gone');
      });

      it('tells the user when no editor answers', async () => {
        dispatchAccepted();
        await vi.advanceTimersByTimeAsync(299);
        expect(errorBanner()).not.toBeVisible();

        await vi.advanceTimersByTimeAsync(1);
        expect(errorBanner()).toHaveTextContent('Editor gone');
      });

      it('ignores the events of other requests', async () => {
        dispatchAccepted('other');
        dispatchApplied(true, 'other');
        await vi.advanceTimersByTimeAsync(1000);

        expect(pane()).toBeInTheDocument();
        expect(errorBanner()).not.toBeVisible();
      });
    });

    describe('cancelling an abandoned run', () => {
      let fetchSpy:MockInstance<typeof window.fetch>;

      beforeEach(() => {
        fetchSpy = vi.spyOn(window, 'fetch').mockResolvedValue(new Response(null, { status: 204 }));
      });

      function cancelCalls() {
        return fetchSpy.mock.calls.filter(([url]) => url === `/ai/text_transform_panes/${RUN}/cancel`);
      }

      it('cancels a generating run when the pane disappears', async () => {
        await mountRun('generating');

        wrapper()!.remove();
        await ctx.nextFrame();

        expect(cancelCalls()).toHaveLength(1);
        expect(cancelCalls()[0][1]).toMatchObject({ method: 'POST', keepalive: true, credentials: 'same-origin' });
      });

      it('cancels a generating run once when the page is left', async () => {
        await mountRun('generating');

        window.dispatchEvent(new Event('pagehide'));
        wrapper()!.remove();
        await ctx.nextFrame();

        expect(cancelCalls()).toHaveLength(1);
      });

      it('leaves cancelling to the close request', async () => {
        await mountRun('generating');

        submit('turbo:submit-start', CLOSE_FORM_ID);
        wrapper()!.remove();
        await ctx.nextFrame();

        expect(cancelCalls()).toHaveLength(0);
      });

      it('cancels when a failed close request removed the pane', async () => {
        await mountRun('generating');

        submit('turbo:submit-start', CLOSE_FORM_ID);
        submit('turbo:submit-end', CLOSE_FORM_ID, { success: false });
        await ctx.nextFrame();

        expect(cancelCalls()).toHaveLength(1);
      });

      it('does not cancel a finished run', async () => {
        await mountRun('done');

        wrapper()!.remove();
        await ctx.nextFrame();

        expect(cancelCalls()).toHaveLength(0);
      });
    });

    it('keeps the focus on the same footer button when a poll replaces the footer', async () => {
      await mountRun('generating');
      button('Cancel').focus();

      const stream = document.createElement('turbo-stream');
      stream.setAttribute('target', 'footer');
      document.body.append(stream);
      stream.dispatchEvent(new CustomEvent('turbo:before-stream-render', { bubbles: true }));
      stream.remove();
      renderFooter('generating', 2);
      await settle();

      expect(button('Cancel')).toHaveFocus();
    });
  });
});
