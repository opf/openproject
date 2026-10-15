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

import AiTextTransformPaneController from './ai-text-transform-pane.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

describe('AiTextTransformPaneController', () => {
  let ctx:StimulusTestContext;

  const CLOSE_FORM_ID = 'ai-text-transform-pane-close';
  const action = (event:string, name:string) => `data-action="${event}->ai-text-transform-pane#${name}"`;

  const HTML = `
<div data-controller="ai-text-transform-pane"
     data-ai-text-transform-pane-close-form-value="${CLOSE_FORM_ID}"
     data-ai-text-transform-pane-copy-value="Copy"
     data-ai-text-transform-pane-copied-value="Copied"
     data-action="keydown.esc->ai-text-transform-pane#close">
  <div data-ai-text-transform-pane-target="pane" tabindex="-1"
       style="position: fixed; top: 40px; right: 16px; width: 340px; height: 260px;">
    <div data-testid="header" ${action('pointerdown', 'beginDrag')}>
      <button type="button" data-testid="close">×</button>
    </div>
    <template data-ai-text-transform-pane-target="raw">Login **works** &lt;again&gt;</template>
    <div>
      <span data-testid="grip" ${action('pointerdown', 'beginDrag')}></span>
      <button type="button" ${action('click', 'copy')}><span data-ai-text-transform-pane-target="copyLabel">Copy</span></button>
    </div>
    <span data-testid="resize-left" data-edge="left" ${action('pointerdown', 'beginResize')}></span>
    <span data-testid="resize-bottom-right" data-edge="bottom-right" ${action('pointerdown', 'beginResize')}></span>
  </div>
</div>`;

  const wrapper = () => ctx.container.querySelector<HTMLElement>('[data-controller="ai-text-transform-pane"]');
  const pane = () => ctx.container.querySelector<HTMLElement>('[data-ai-text-transform-pane-target="pane"]')!;
  const rect = () => pane().getBoundingClientRect().toJSON() as DOMRect;
  const byTestId = (id:string) => ctx.screen.getByTestId(id);

  function pointer(type:string, target:EventTarget, clientX:number, clientY:number):void {
    target.dispatchEvent(new PointerEvent(type, { bubbles: true, cancelable: true, clientX, clientY }));
  }

  function dragBy(handle:HTMLElement, dx:number, dy:number):void {
    const start = handle.getBoundingClientRect();
    pointer('pointerdown', handle, start.left, start.top);
    pointer('pointermove', window, start.left + dx, start.top + dy);
    pointer('pointerup', window, start.left + dx, start.top + dy);
  }

  function pressEscape():void {
    pane().dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
  }

  beforeEach(async () => {
    ctx = await setupStimulusTest({ controllers: { 'ai-text-transform-pane': AiTextTransformPaneController } });
    await ctx.mount(HTML);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    ctx.container.querySelector('[data-ai-text-transform-pane-target="pane"]')?.removeAttribute('style');
    ctx.dispose();
  });

  it('focuses the pane on connect', () => {
    expect(document.activeElement).toBe(pane());
  });

  describe('dragging', () => {
    it('moves the pane by the header and pins it with left and top', () => {
      const before = rect();
      dragBy(byTestId('header'), -20, 30);

      expect(pane().style.left).toBe(`${before.left - 20}px`);
      expect(pane().style.top).toBe(`${before.top + 30}px`);
      expect(pane().style.right).toBe('auto');
      expect(pane().style.bottom).toBe('auto');
    });

    it('moves the pane by the footer grip', () => {
      const before = rect();
      dragBy(byTestId('grip'), -10, 10);

      expect(rect().left).toBe(before.left - 10);
      expect(rect().top).toBe(before.top + 10);
    });

    it('does not start a drag on a button in the header', () => {
      dragBy(byTestId('close'), -20, 30);

      expect(pane().style.left).toBe('');
    });

    it('keeps the pane inside the viewport', () => {
      dragBy(byTestId('header'), -5000, -5000);
      expect(pane().style.left).toBe('8px');
      expect(pane().style.top).toBe('8px');

      dragBy(byTestId('header'), 5000, 5000);
      expect(rect().right).toBe(window.innerWidth - 8);
      expect(rect().bottom).toBe(window.innerHeight - 8);
    });

    it('stops following the pointer after pointerup', () => {
      dragBy(byTestId('header'), -20, 30);
      const after = rect();
      pointer('pointermove', window, 0, 0);

      expect(rect()).toEqual(after);
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
  });

  it('restores the pinned geometry when the pane is replaced', async () => {
    dragBy(byTestId('header'), -20, 30);
    dragBy(byTestId('resize-bottom-right'), -10, 10);
    const geometry = rect();

    wrapper()!.remove();
    await ctx.mount(HTML);

    expect(rect()).toEqual(geometry);
  });

  describe('Escape', () => {
    it('submits the close form when it exists', () => {
      ctx.appendHTML(`<form id="${CLOSE_FORM_ID}"></form>`);
      const form = document.getElementById(CLOSE_FORM_ID) as HTMLFormElement;
      const submit = vi.spyOn(form, 'requestSubmit').mockImplementation(() => undefined);

      pressEscape();

      expect(submit).toHaveBeenCalled();
      expect(wrapper()).not.toBeNull();
    });

    it('removes the pane without a close form', () => {
      pressEscape();

      expect(wrapper()).toBeNull();
    });
  });

  it('copies the raw text and shows the copied label for a moment', async () => {
    const writeText = vi.spyOn(navigator.clipboard, 'writeText').mockResolvedValue(undefined);
    const label = ctx.container.querySelector('[data-ai-text-transform-pane-target="copyLabel"]')!;
    vi.useFakeTimers();

    await ctx.getController<AiTextTransformPaneController>('ai-text-transform-pane').copy();

    expect(writeText).toHaveBeenCalledWith('Login **works** <again>');
    expect(label).toHaveTextContent('Copied');

    vi.advanceTimersByTime(1500);
    expect(label).toHaveTextContent('Copy');
  });
});
