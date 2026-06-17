/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */
/* eslint-disable @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-assignment */

import ExpandableTextController from './expandable-text.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

const singleLineTemplate = `
  <div data-controller="expandable-text" data-expandable-text-expanded-value="false" data-expandable-text-mode-value="single_line" data-expandable-text-inline-value="true">
    <div data-expandable-text-target="truncate" style="width: 200px; overflow: hidden;">
      <span class="Truncate-text" style="display: inline-block; white-space: nowrap;">
        This is a very long text that should be truncated when it exceeds the container width
      </span>
    </div>
    <div data-expandable-text-target="expander">
      <button type="button">Toggle</button>
    </div>
  </div>
`;

const multiLineTemplate = `
  <div data-controller="expandable-text" data-expandable-text-expanded-value="false" data-expandable-text-mode-value="multi_line" data-expandable-text-inline-value="true">
    <div data-expandable-text-target="truncate" class="op-vertical-truncate op-vertical-truncate--lines-3" style="overflow: hidden;">
      <p>Line one of a multi-line block of text.</p>
      <p>Line two with more content.</p>
      <p>Line three extends beyond the clamp limit.</p>
      <p>Line four is hidden by the clamp.</p>
    </div>
    <div data-expandable-text-target="expander">
      <button type="button">Toggle</button>
    </div>
  </div>
`;

const dialogTemplate = `
  <div data-controller="expandable-text" data-expandable-text-expanded-value="false" data-expandable-text-mode-value="multi_line" data-expandable-text-inline-value="false">
    <div data-expandable-text-target="truncate" class="op-vertical-truncate op-vertical-truncate--lines-3" style="overflow: hidden;">
      <p>Content that opens in a dialog.</p>
    </div>
    <div data-expandable-text-target="expander">
      <button type="button" data-show-dialog-id="my-dialog">Toggle</button>
    </div>
  </div>
`;

describe('ExpandableTextController', () => {
  let ctx:StimulusTestContext;
  let originalI18n:any;

  beforeEach(() => {
    originalI18n = (window as any).I18n;
    if (originalI18n && typeof originalI18n.store === 'function') {
      originalI18n.store({
        en: {
          js: {
            label_expand_text: 'Expand text',
            label_collapse_text: 'Collapse text',
          },
        },
      });
    }
  });

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'expandable-text': ExpandableTextController },
    });
  });

  afterEach(() => {
    try {
      ctx.dispose();
    } finally {
      if (originalI18n) {
        (window as any).I18n = originalI18n;
      }
    }
  });

  describe('single-line mode', () => {
    describe('initialization', () => {
      beforeEach(async () => {
        await ctx.mount(singleLineTemplate);
      });

      it('connects successfully', () => {
        const controller = ctx.getController('expandable-text');

        expect(controller).toBeDefined();
      });

      it('sets initial aria attributes on expander button', () => {
        const button = ctx.screen.getByRole('button', { name: 'Expand text', hidden: true });

        expect(button).toHaveAttribute('aria-expanded', 'false');
      });

      it('adds Truncate--expanded class when expanded value is true', async () => {
        const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;

        expect(truncateEl).not.toHaveClass('Truncate--expanded');

        const controller = ctx.getController<ExpandableTextController>('expandable-text');

        controller.expandedValue = true;
        await ctx.nextFrame();

        expect(truncateEl).toHaveClass('Truncate--expanded');
      });
    });

    describe('expander button click', () => {
      beforeEach(async () => {
        await ctx.mount(singleLineTemplate);
      });

      it('toggles expanded state', async () => {
        const button = ctx.screen.getByRole('button', { name: 'Expand text', hidden: true });
        const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;

        expect(truncateEl).not.toHaveClass('Truncate--expanded');
        expect(button).toHaveAttribute('aria-expanded', 'false');

        button.click();
        await ctx.nextFrame();

        expect(truncateEl).toHaveClass('Truncate--expanded');
        expect(button).toHaveAttribute('aria-expanded', 'true');
        expect(button).toHaveAttribute('aria-label', 'Collapse text');

        button.click();
        await ctx.nextFrame();

        expect(truncateEl).not.toHaveClass('Truncate--expanded');
        expect(button).toHaveAttribute('aria-expanded', 'false');
        expect(button).toHaveAttribute('aria-label', 'Expand text');
      });
    });

    describe('expandedValue changes', () => {
      beforeEach(async () => {
        await ctx.mount(singleLineTemplate);
      });

      it('updates aria-label when expanded', async () => {
        const button = ctx.screen.getByRole('button', { name: 'Expand text', hidden: true });
        const controller = ctx.getController<ExpandableTextController>('expandable-text');

        expect(button).toHaveAttribute('aria-label', 'Expand text');

        controller.expandedValue = true;
        await ctx.nextFrame();

        expect(button).toHaveAttribute('aria-label', 'Collapse text');
      });

      it('updates aria-expanded attribute', async () => {
        const button = ctx.screen.getByRole('button', { name: 'Expand text', hidden: true });
        const controller = ctx.getController<ExpandableTextController>('expandable-text');

        expect(button).toHaveAttribute('aria-expanded', 'false');

        controller.expandedValue = true;
        await ctx.nextFrame();

        expect(button).toHaveAttribute('aria-expanded', 'true');
      });

      it('toggles Truncate--expanded class', async () => {
        const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;
        const controller = ctx.getController<ExpandableTextController>('expandable-text');

        expect(truncateEl).not.toHaveClass('Truncate--expanded');

        controller.expandedValue = true;
        await ctx.nextFrame();

        expect(truncateEl).toHaveClass('Truncate--expanded');

        controller.expandedValue = false;
        await ctx.nextFrame();

        expect(truncateEl).not.toHaveClass('Truncate--expanded');
      });
    });

    describe('expander visibility', () => {
      // Wait multiple frames to ensure ResizeObserver has fired
      const waitForResize = async () => {
        await ctx.nextFrame();
        await ctx.nextFrame();
      };

      it('hides expander when content is not truncated', async () => {
        const shortTextTemplate = `
          <div data-controller="expandable-text" data-expandable-text-expanded-value="false">
            <div data-expandable-text-target="truncate" style="width: 500px; overflow: hidden;">
              <span class="Truncate-text" style="display: inline-block; white-space: nowrap;">
                Short text
              </span>
            </div>
            <div data-expandable-text-target="expander">
              <button type="button">Toggle</button>
            </div>
          </div>
        `;

        ctx.appendHTML(shortTextTemplate);
        await waitForResize();

        const expander = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="expander"]')!;

        expect(expander.hidden).toBe(true);
      });

      it('shows expander when content is truncated', async () => {
        const longTextTemplate = `
          <div data-controller="expandable-text" data-expandable-text-expanded-value="false">
            <div data-expandable-text-target="truncate" style="width: 50px; overflow: hidden;">
              <span class="Truncate-text" style="display: inline-block; white-space: nowrap; width: 300px;">
                This is a very long text that should definitely be truncated
              </span>
            </div>
            <div data-expandable-text-target="expander">
              <button type="button">Toggle</button>
            </div>
          </div>
        `;

        ctx.appendHTML(longTextTemplate);

        const truncateText = ctx.container.querySelector<HTMLElement>('.Truncate-text')!;
        Object.defineProperty(truncateText, 'scrollWidth', { value: 300, configurable: true });
        Object.defineProperty(truncateText, 'clientWidth', { value: 50, configurable: true });

        await waitForResize();

        const expander = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="expander"]')!;

        expect(expander.hidden).toBe(false);
      });
    });

    describe('resize() method', () => {
      it('calls update() when resize is triggered', async () => {
        await ctx.mount(singleLineTemplate);

        const controller = ctx.getController<ExpandableTextController>('expandable-text');

        // Spy on the private update method to verify resize() calls it
        const updateSpy = vi.spyOn(controller as any, 'update');

        controller.resize();

        expect(updateSpy).toHaveBeenCalledWith();
      });

      it('updates expander visibility when content dimensions change', async () => {
        await ctx.mount(singleLineTemplate);

        const controller = ctx.getController<ExpandableTextController>('expandable-text');
        const expander = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="expander"]')!;
        const truncateText = ctx.container.querySelector<HTMLElement>('.Truncate-text')!;

        const originalScrollWidth = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'scrollWidth');
        const originalClientWidth = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'clientWidth');

        // Simulate not truncated: scrollWidth === clientWidth
        Object.defineProperty(truncateText, 'scrollWidth', { configurable: true, value: 100 });
        Object.defineProperty(truncateText, 'clientWidth', { configurable: true, value: 100 });
        controller.resize();

        expect(expander.hidden).toBe(true);

        // Simulate truncated: scrollWidth > clientWidth
        Object.defineProperty(truncateText, 'scrollWidth', { configurable: true, value: 200 });
        Object.defineProperty(truncateText, 'clientWidth', { configurable: true, value: 100 });
        controller.resize();

        expect(expander.hidden).toBe(false);

        // Simulate not truncated again
        Object.defineProperty(truncateText, 'scrollWidth', { configurable: true, value: 50 });
        Object.defineProperty(truncateText, 'clientWidth', { configurable: true, value: 50 });
        controller.resize();

        expect(expander.hidden).toBe(true);

        if (originalScrollWidth) {
          Object.defineProperty(HTMLElement.prototype, 'scrollWidth', originalScrollWidth);
        }
        if (originalClientWidth) {
          Object.defineProperty(HTMLElement.prototype, 'clientWidth', originalClientWidth);
        }
      });

      it('keeps expander visible when expanded even if not truncated', async () => {
        await ctx.mount(singleLineTemplate);

        const controller = ctx.getController<ExpandableTextController>('expandable-text');
        const expander = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="expander"]')!;

        // Initially short text, expander should be hidden
        controller.resize();

        expect(expander.hidden).toBe(true);

        // Expand the text
        controller.expandedValue = true;
        await ctx.nextFrame();

        // When expanded, expander should remain visible even if not truncated
        expect(expander.hidden).toBe(false);
      });
    });
  });

  describe('multi-line mode', () => {
    it('connects successfully', async () => {
      await ctx.mount(multiLineTemplate);

      const controller = ctx.getController('expandable-text');

      expect(controller).toBeDefined();
    });

    it('detects vertical truncation via scrollHeight > clientHeight', async () => {
      await ctx.mount(multiLineTemplate);

      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;
      const expander = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="expander"]')!;

      Object.defineProperty(truncateEl, 'scrollHeight', { configurable: true, value: 200 });
      Object.defineProperty(truncateEl, 'clientHeight', { configurable: true, value: 60 });

      const controller = ctx.getController<ExpandableTextController>('expandable-text');
      controller.resize();

      expect(expander.hidden).toBe(false);
    });

    it('hides expander when content fits within line-clamp', async () => {
      await ctx.mount(multiLineTemplate);

      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;
      const expander = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="expander"]')!;

      Object.defineProperty(truncateEl, 'scrollHeight', { configurable: true, value: 60 });
      Object.defineProperty(truncateEl, 'clientHeight', { configurable: true, value: 60 });

      const controller = ctx.getController<ExpandableTextController>('expandable-text');
      controller.resize();

      expect(expander.hidden).toBe(true);
    });

    it('toggles op-vertical-truncate--expanded class instead of Truncate--expanded', async () => {
      await ctx.mount(multiLineTemplate);

      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;
      const controller = ctx.getController<ExpandableTextController>('expandable-text');

      controller.expandedValue = true;
      await ctx.nextFrame();

      expect(truncateEl).toHaveClass('op-vertical-truncate--expanded');
      expect(truncateEl).not.toHaveClass('Truncate--expanded');

      controller.expandedValue = false;
      await ctx.nextFrame();

      expect(truncateEl).not.toHaveClass('op-vertical-truncate--expanded');
    });

    it('handles click to toggle expansion', async () => {
      await ctx.mount(multiLineTemplate);

      const button = ctx.screen.getByRole('button', { name: 'Expand text', hidden: true });
      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;

      button.click();
      await ctx.nextFrame();

      expect(truncateEl).toHaveClass('op-vertical-truncate--expanded');
      expect(button).toHaveAttribute('aria-expanded', 'true');

      button.click();
      await ctx.nextFrame();

      expect(truncateEl).not.toHaveClass('op-vertical-truncate--expanded');
      expect(button).toHaveAttribute('aria-expanded', 'false');
    });
  });

  describe('dialog mode (inline: false)', () => {
    it('removes the aria-expanded attribute from the expander button', async () => {
      // HellipButton always renders aria-expanded="false"; a modal-dialog trigger
      // should not advertise a disclosure state, so the controller strips it.
      const dialogWithAriaTemplate = `
        <div data-controller="expandable-text" data-expandable-text-expanded-value="false" data-expandable-text-mode-value="multi_line" data-expandable-text-inline-value="false">
          <div data-expandable-text-target="truncate" class="op-vertical-truncate op-vertical-truncate--lines-3" style="overflow: hidden;">
            <p>Content that opens in a dialog.</p>
          </div>
          <div data-expandable-text-target="expander">
            <button type="button" data-show-dialog-id="my-dialog" aria-haspopup="dialog" aria-controls="my-dialog" aria-expanded="false">Toggle</button>
          </div>
        </div>
      `;

      await ctx.mount(dialogWithAriaTemplate);

      const button = ctx.container.querySelector<HTMLButtonElement>('[data-expandable-text-target="expander"] button')!;

      expect(button).not.toHaveAttribute('aria-expanded');
      expect(button).toHaveAttribute('aria-haspopup', 'dialog');
    });

    it('does not attach click handler to expander', async () => {
      await ctx.mount(dialogTemplate);

      const button = ctx.container.querySelector<HTMLButtonElement>('[data-expandable-text-target="expander"] button')!;
      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;

      button.click();
      await ctx.nextFrame();

      expect(truncateEl).not.toHaveClass('op-vertical-truncate--expanded');
    });

    it('still manages expander visibility based on truncation', async () => {
      await ctx.mount(dialogTemplate);

      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;
      const expander = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="expander"]')!;

      Object.defineProperty(truncateEl, 'scrollHeight', { configurable: true, value: 200 });
      Object.defineProperty(truncateEl, 'clientHeight', { configurable: true, value: 60 });

      const controller = ctx.getController<ExpandableTextController>('expandable-text');
      controller.resize();

      expect(expander.hidden).toBe(false);
    });

    it('preserves server-rendered expander when content fits but has omitted paragraphs', async () => {
      const serverVisibleTemplate = `
        <div data-controller="expandable-text" data-expandable-text-expanded-value="false" data-expandable-text-mode-value="multi_line" data-expandable-text-inline-value="false">
          <div data-expandable-text-target="truncate" class="op-vertical-truncate op-vertical-truncate--lines-3" style="overflow: hidden;">
            <span>Short first paragraph that fits.</span>
          </div>
          <div data-expandable-text-target="expander">
            <button type="button" data-show-dialog-id="my-dialog">Toggle</button>
          </div>
        </div>
      `;

      await ctx.mount(serverVisibleTemplate);

      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;
      const expander = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="expander"]')!;

      // Content fits — no physical truncation
      Object.defineProperty(truncateEl, 'scrollHeight', { configurable: true, value: 40 });
      Object.defineProperty(truncateEl, 'clientHeight', { configurable: true, value: 60 });

      const controller = ctx.getController<ExpandableTextController>('expandable-text');
      controller.resize();

      // Expander must stay visible — server decided to show it because full content has more paragraphs
      expect(expander.hidden).toBe(false);
    });

    it('toggles a server-hidden expander based on truncation', async () => {
      const serverHiddenTemplate = `
        <div data-controller="expandable-text" data-expandable-text-expanded-value="false" data-expandable-text-mode-value="multi_line" data-expandable-text-inline-value="false">
          <div data-expandable-text-target="truncate" class="op-vertical-truncate op-vertical-truncate--lines-3" style="overflow: hidden;">
            <span>Single paragraph.</span>
          </div>
          <div data-expandable-text-target="expander" hidden>
            <button type="button" data-show-dialog-id="my-dialog">Toggle</button>
          </div>
        </div>
      `;

      await ctx.mount(serverHiddenTemplate);

      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="truncate"]')!;
      const expander = ctx.container.querySelector<HTMLElement>('[data-expandable-text-target="expander"]')!;
      const controller = ctx.getController<ExpandableTextController>('expandable-text');

      // Content fits — server-hidden expander stays hidden
      Object.defineProperty(truncateEl, 'scrollHeight', { configurable: true, value: 60 });
      Object.defineProperty(truncateEl, 'clientHeight', { configurable: true, value: 60 });
      controller.resize();

      expect(expander.hidden).toBe(true);

      // Becomes truncated — expander is revealed
      Object.defineProperty(truncateEl, 'scrollHeight', { configurable: true, value: 200 });
      controller.resize();

      expect(expander.hidden).toBe(false);

      // No longer truncated after a resize — expander is hidden again
      Object.defineProperty(truncateEl, 'scrollHeight', { configurable: true, value: 60 });
      controller.resize();

      expect(expander.hidden).toBe(true);
    });
  });
});
