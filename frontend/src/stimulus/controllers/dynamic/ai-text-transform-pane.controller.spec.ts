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
import AiTextTransformPaneController from './ai-text-transform-pane.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('AiTextTransformPaneController', () => {
  let ctx:StimulusTestContext;

  const CLOSE_FORM_ID = 'ai-text-transform-pane-close';
  const action = (event:string, name:string) => `data-action="${event}->ai-text-transform-pane#${name}"`;

  const HTML = `
<div data-controller="ai-text-transform-pane"
     data-ai-text-transform-pane-close-form-value="${CLOSE_FORM_ID}"
     data-action="keydown.esc->ai-text-transform-pane#close resize@window->ai-text-transform-pane#keepInViewport">
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
    ctx = await setupStimulusTest({ controllers: { 'ai-text-transform-pane': AiTextTransformPaneController } });
    await ctx.mount(HTML);
  });

  afterEach(() => {
    vi.restoreAllMocks();
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
});
