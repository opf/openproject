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


import FlashController, { LIVE_REGION_ANNOUNCEMENT_DELAY, SUCCESS_AUTOHIDE_TIMEOUT } from './flash.controller';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

interface LiveRegionTestElement extends HTMLElement {
  announce(message:string, options:unknown):void;
}

describe('FlashController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { flash: FlashController },
    });
  });

  afterEach(() => {
    document.documentElement.removeAttribute('data-turbo-preview');
    vi.useRealTimers();
    vi.restoreAllMocks();
    ctx?.dispose();
  });

  function renderFlash(attributes:string, content = 'Message') {
    ctx.appendHTML(`
      <div data-controller="flash">
        <live-region data-testid="live-region"></live-region>
        <div data-flash-target="item" ${attributes}>
          ${content}
        </div>
      </div>
    `);
  }

  // The real live-region element is provided globally in the app layout.
  // In this isolated controller spec, we stub its announce method directly.
  function stubLiveRegionAnnouncement(announceSpy:LiveRegionTestElement['announce']) {
    const liveRegion = ctx.screen.getByTestId('live-region') as unknown as LiveRegionTestElement;

    liveRegion.announce = announceSpy;
  }

  describe('announcements', () => {
    it('announces flash items politely by default', async () => {
      vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
      renderFlash('data-announcement="Saved"', 'Saved');
      const announceSpy:LiveRegionTestElement['announce'] = vi.fn((_message:string, _options:unknown) => undefined);
      stubLiveRegionAnnouncement(announceSpy);
      await ctx.nextFrame();

      const item = ctx.screen.getByText('Saved');
      // Keep the delayed live-region update deterministic.
      vi.advanceTimersByTime(LIVE_REGION_ANNOUNCEMENT_DELAY);

      expect(announceSpy).toHaveBeenCalledWith('Saved', { politeness: 'polite', from: item });
    });

    it('announces urgent flash items assertively', async () => {
      vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
      renderFlash('data-announcement="Invalid input" data-politeness="assertive"', 'Invalid input');
      const announceSpy:LiveRegionTestElement['announce'] = vi.fn((_message:string, _options:unknown) => undefined);
      stubLiveRegionAnnouncement(announceSpy);
      await ctx.nextFrame();

      const item = ctx.screen.getByText('Invalid input');
      vi.advanceTimersByTime(LIVE_REGION_ANNOUNCEMENT_DELAY);

      expect(announceSpy).toHaveBeenCalledWith('Invalid input', { politeness: 'assertive', from: item });
    });

    it('does not announce while Turbo is rendering a cached preview', async () => {
      vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
      document.documentElement.setAttribute('data-turbo-preview', '');
      renderFlash('data-announcement="Saved"', 'Saved');
      const announceSpy:LiveRegionTestElement['announce'] = vi.fn((_message:string, _options:unknown) => undefined);
      stubLiveRegionAnnouncement(announceSpy);
      await ctx.nextFrame();
      vi.advanceTimersByTime(LIVE_REGION_ANNOUNCEMENT_DELAY);

      expect(announceSpy).not.toHaveBeenCalled();
    });

    it('does not announce flash items that were removed before the deferred announcement', async () => {
      vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
      renderFlash('data-announcement="Saved"', 'Saved');
      const announceSpy:LiveRegionTestElement['announce'] = vi.fn((_message:string, _options:unknown) => undefined);
      stubLiveRegionAnnouncement(announceSpy);
      await ctx.nextFrame();

      ctx.screen.getByText('Saved').remove();
      vi.advanceTimersByTime(LIVE_REGION_ANNOUNCEMENT_DELAY);

      expect(announceSpy).not.toHaveBeenCalled();
    });
  });

  describe('without autohide', () => {
    it('keeps flash items visible', async () => {
      await ctx.mount(`
        <div data-controller="flash">
          <div data-flash-target="item" data-autohide="true" role="alert">
            Success message
          </div>
        </div>
      `);

      expect(ctx.screen.getByRole('alert')).toBeInTheDocument();
    });
  });

  describe('with autohide', () => {
    it('schedules removal of autohide items', async () => {
      const timeoutSpy = vi.spyOn(globalThis, 'setTimeout');

      await ctx.mount(`
        <div data-controller="flash" data-flash-autohide-value="true">
          <div data-flash-target="item" data-autohide="true" role="alert">
            Success message
          </div>
        </div>
      `);

      const autohideCall = timeoutSpy.mock.calls.find(([, delay]) => delay === SUCCESS_AUTOHIDE_TIMEOUT);

      expect(autohideCall).toBeDefined();

      timeoutSpy.mockRestore();
    });

    it('does not schedule removal for items without data-autohide', async () => {
      const timeoutSpy = vi.spyOn(globalThis, 'setTimeout');

      await ctx.mount(`
        <div data-controller="flash" data-flash-autohide-value="true">
          <div data-flash-target="item" role="alert">
            Error message
          </div>
        </div>
      `);

      const autohideCall = timeoutSpy.mock.calls.find(([, delay]) => delay === SUCCESS_AUTOHIDE_TIMEOUT);

      expect(autohideCall).toBeUndefined();

      timeoutSpy.mockRestore();
    });
  });

  describe('flashTargetDisconnected', () => {
    it('removes empty item containers when flash target is removed', async () => {
      await ctx.mount(`
        <div data-controller="flash">
          <div data-flash-target="item" data-testid="item-container"></div>
          <div data-flash-target="flash" data-testid="flash-content">Content</div>
        </div>
      `);

      ctx.screen.getByTestId('flash-content').remove();
      await ctx.nextFrame();

      expect(ctx.screen.queryByTestId('item-container')).not.toBeInTheDocument();
    });
  });

  describe('interaction pause/resume', () => {
    it('pauses and resumes autohide timer on keyboard interaction', async () => {
      // Focused messages should stay visible while users interact with controls inside them.
      const timeoutSpy = vi.spyOn(globalThis, 'setTimeout');
      const clearTimeoutSpy = vi.spyOn(globalThis, 'clearTimeout');

      ctx.appendHTML(`
        <div data-controller="flash" data-flash-autohide-value="true">
          <div data-flash-target="item" data-autohide="true" role="status">
            <button>Action</button>
          </div>
        </div>
      `);
      await ctx.nextFrame();

      const button = ctx.screen.getByRole('button');
      button.focus();
      await ctx.nextFrame();

      expect(clearTimeoutSpy).toHaveBeenCalled();
      timeoutSpy.mockClear();

      button.blur();
      await ctx.nextFrame();

      const autohideCall = timeoutSpy.mock.calls.find(([, delay]) => delay === SUCCESS_AUTOHIDE_TIMEOUT);
      expect(autohideCall).toBeDefined();
    });

    it('pauses and resumes autohide timer on mouse interaction', async () => {
      // Hovered messages should also pause so users have time to read them.
      const timeoutSpy = vi.spyOn(globalThis, 'setTimeout');
      const clearTimeoutSpy = vi.spyOn(globalThis, 'clearTimeout');

      ctx.appendHTML(`
        <div data-controller="flash" data-flash-autohide-value="true">
          <div data-flash-target="item" data-autohide="true" role="status" data-testid="flash-item">
            Message
          </div>
        </div>
      `);
      await ctx.nextFrame();

      const item = ctx.screen.getByTestId('flash-item');
      item.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
      await ctx.nextFrame();

      expect(clearTimeoutSpy).toHaveBeenCalled();
      timeoutSpy.mockClear();

      item.dispatchEvent(new MouseEvent('mouseleave', { bubbles: true }));
      await ctx.nextFrame();

      const autohideCall = timeoutSpy.mock.calls.find(([, delay]) => delay === SUCCESS_AUTOHIDE_TIMEOUT);
      expect(autohideCall).toBeDefined();
    });
  });
});
