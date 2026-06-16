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

import TruncationController from './truncation.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

const truncationTemplate = `
  <div data-controller="truncation" data-truncation-expanded-value="false">
    <div data-truncation-target="truncate" style="width: 200px; overflow: hidden;">
      <span class="Truncate-text" style="display: inline-block; white-space: nowrap;">
        This is a very long text that should be truncated when it exceeds the container width
      </span>
    </div>
    <div data-truncation-target="expander">
      <button type="button">Toggle</button>
    </div>
  </div>
`;

describe('TruncationController', () => {
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
      controllers: { truncation: TruncationController },
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

  describe('initialization', () => {
    beforeEach(async () => {
      await ctx.mount(truncationTemplate);
    });

    it('connects successfully', () => {
      const controller = ctx.getController('truncation');

      expect(controller).toBeDefined();
    });

    it('sets initial aria attributes on expander button', () => {
      const button = ctx.screen.getByRole('button', { name: 'Expand text', hidden: true });

      expect(button).toHaveAttribute('aria-expanded', 'false');
    });

    it('adds Truncate--expanded class when expanded value is true', async () => {
      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-truncation-target="truncate"]')!;

      expect(truncateEl).not.toHaveClass('Truncate--expanded');

      const controller = ctx.getController<TruncationController>('truncation');

      controller.expandedValue = true;
      await ctx.nextFrame();

      expect(truncateEl).toHaveClass('Truncate--expanded');
    });
  });

  describe('expander button click', () => {
    beforeEach(async () => {
      await ctx.mount(truncationTemplate);
    });

    it('toggles expanded state', async () => {
      const button = ctx.screen.getByRole('button', { name: 'Expand text', hidden: true });
      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-truncation-target="truncate"]')!;

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
      await ctx.mount(truncationTemplate);
    });

    it('updates aria-label when expanded', async () => {
      const button = ctx.screen.getByRole('button', { name: 'Expand text', hidden: true });
      const controller = ctx.getController<TruncationController>('truncation');

      expect(button).toHaveAttribute('aria-label', 'Expand text');

      controller.expandedValue = true;
      await ctx.nextFrame();

      expect(button).toHaveAttribute('aria-label', 'Collapse text');
    });

    it('updates aria-expanded attribute', async () => {
      const button = ctx.screen.getByRole('button', { name: 'Expand text', hidden: true });
      const controller = ctx.getController<TruncationController>('truncation');

      expect(button).toHaveAttribute('aria-expanded', 'false');

      controller.expandedValue = true;
      await ctx.nextFrame();

      expect(button).toHaveAttribute('aria-expanded', 'true');
    });

    it('toggles Truncate--expanded class', async () => {
      const truncateEl = ctx.container.querySelector<HTMLElement>('[data-truncation-target="truncate"]')!;
      const controller = ctx.getController<TruncationController>('truncation');

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
        <div data-controller="truncation" data-truncation-expanded-value="false">
          <div data-truncation-target="truncate" style="width: 500px; overflow: hidden;">
            <span class="Truncate-text" style="display: inline-block; white-space: nowrap;">
              Short text
            </span>
          </div>
          <div data-truncation-target="expander">
            <button type="button">Toggle</button>
          </div>
        </div>
      `;

      await ctx.mount(shortTextTemplate);
      await ctx.nextFrame();

      const expander = ctx.container.querySelector<HTMLElement>('[data-truncation-target="expander"]')!;

      expect(expander.hidden).toBe(true);
    });

    it('shows expander when content is truncated', async () => {
      const longTextTemplate = `
        <div data-controller="truncation" data-truncation-expanded-value="false">
          <div data-truncation-target="truncate" style="width: 50px; overflow: hidden;">
            <span class="Truncate-text" style="display: inline-block; white-space: nowrap; width: 300px;">
              This is a very long text that should definitely be truncated
            </span>
          </div>
          <div data-truncation-target="expander">
            <button type="button">Toggle</button>
          </div>
        </div>
      `;

      ctx.appendHTML(longTextTemplate);

      const truncateText = ctx.container.querySelector<HTMLElement>('.Truncate-text')!;
      Object.defineProperty(truncateText, 'scrollWidth', { value: 300, configurable: true });
      Object.defineProperty(truncateText, 'clientWidth', { value: 50, configurable: true });

      await waitForResize();

      const expander = ctx.container.querySelector<HTMLElement>('[data-truncation-target="expander"]')!;

      expect(expander.hidden).toBe(false);
    });
  });

  describe('resize() method', () => {
    it('updates expander visibility when content dimensions change', async () => {
      await ctx.mount(truncationTemplate);

      const controller = ctx.getController<TruncationController>('truncation');
      const expander = ctx.container.querySelector<HTMLElement>('[data-truncation-target="expander"]')!;
      const truncateText = ctx.container.querySelector<HTMLElement>('.Truncate-text')!;

      const originalScrollWidth = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'scrollWidth');
      const originalClientWidth = Object.getOwnPropertyDescriptor(HTMLElement.prototype, 'clientWidth');

      Object.defineProperty(truncateText, 'scrollWidth', { configurable: true, value: 100 });
      Object.defineProperty(truncateText, 'clientWidth', { configurable: true, value: 100 });
      controller.resize();

      expect(expander.hidden).toBe(true);

      Object.defineProperty(truncateText, 'scrollWidth', { configurable: true, value: 200 });
      Object.defineProperty(truncateText, 'clientWidth', { configurable: true, value: 100 });
      controller.resize();

      expect(expander.hidden).toBe(false);

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
      await ctx.mount(truncationTemplate);

      const controller = ctx.getController<TruncationController>('truncation');
      const expander = ctx.container.querySelector<HTMLElement>('[data-truncation-target="expander"]')!;

      controller.resize();

      expect(expander.hidden).toBe(true);

      controller.expandedValue = true;
      await ctx.nextFrame();

      expect(expander.hidden).toBe(false);
    });
  });
});
