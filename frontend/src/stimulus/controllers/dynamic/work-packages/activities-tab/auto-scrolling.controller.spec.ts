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

import { vi, type Mock } from 'vitest';
import { Controller } from '@hotwired/stimulus';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type AutoScrollingControllerType from './auto-scrolling.controller';
import { ViewPortServiceInterface } from './services/view-port-service';

const HIGHLIGHTED_CLASS = '--anchor-highlighted';

// The auto-scrolling controller reaches its scroll target and viewport flags
// through the index controller's viewport service. A real index controller pulls
// in the whole activities tab, so this stub exposes only what the scroll paths read.
class StubIndexController extends Controller {
  sortingAscending = false;

  sortingDescending = true;

  viewPortService:ViewPortServiceInterface = {
    scrollableContainer: null,
    isMobile: () => false,
    isWithinNotificationCenter: () => false,
    isWithinSplitScreen: () => false,
    isJournalsContainerScrolledToBottom: () => false,
    anchorScrollOffset: () => 0,
  };
}

describe('Activities tab auto-scrolling controller', () => {
  let ctx:StimulusTestContext;
  let AutoScrollingController:typeof AutoScrollingControllerType;
  let scrollTo:Mock;

  beforeAll(async () => {
    ({ default: AutoScrollingController } = await import('./auto-scrolling.controller'));
  });

  beforeEach(async () => {
    window.location.hash = '';
    scrollTo = vi.fn();

    ctx = await setupStimulusTest({
      controllers: {
        'work-packages--activities-tab--index': StubIndexController,
        'work-packages--activities-tab--auto-scrolling': AutoScrollingController,
      },
    });
  });

  afterEach(() => {
    window.location.hash = '';
    ctx.dispose();
    vi.restoreAllMocks();
  });

  async function renderActivities(resolvedCommentId?:number) {
    const resolvedAttr =
      resolvedCommentId === undefined
        ? ''
        : `data-work-packages--activities-tab--auto-scrolling-resolved-comment-id-value="${resolvedCommentId}"`;

    await ctx.mount(`
      <div id="work-packages--activities-tab--index"
           data-controller="work-packages--activities-tab--index">
        <div id="scroller">
          <div data-controller="work-packages--activities-tab--auto-scrolling" ${resolvedAttr}>
            <div data-anchor-comment-id="131">comment 131</div>
            <div data-anchor-comment-id="139">comment 139</div>
          </div>
        </div>
      </div>
    `);

    const scroller = ctx.container.querySelector<HTMLElement>('#scroller')!;
    scroller.scrollTo = scrollTo;

    const indexEl = ctx.container.querySelector('[data-controller~="work-packages--activities-tab--index"]')!;
    const index = ctx.getController<StubIndexController>('work-packages--activities-tab--index', indexEl);
    index.viewPortService.scrollableContainer = scroller;

    return {
      index,
      scroller,
      el131: ctx.container.querySelector<HTMLElement>('[data-anchor-comment-id="131"]')!,
      el139: ctx.container.querySelector<HTMLElement>('[data-anchor-comment-id="139"]')!,
    };
  }

  function changeHash(hash:string) {
    window.location.hash = hash;
    window.dispatchEvent(new HashChangeEvent('hashchange'));
  }

  // Appends a link inside the controller element, the way a comment body would
  // render one, and returns it for dispatching clicks at.
  function addCommentBodyLink(href:string) {
    const root = ctx.container.querySelector('[data-controller~="work-packages--activities-tab--auto-scrolling"]')!;
    const link = document.createElement('a');
    link.href = href;
    link.textContent = 'see that comment';
    root.appendChild(link);
    return link;
  }

  function clickLink(link:HTMLAnchorElement, init:MouseEventInit = {}) {
    // A click the controller leaves alone would otherwise drive a real navigation
    // and tear down the test page; cancel the native default after the controller
    // (on this.element) has already had its turn in the bubble phase.
    const blockNavigation = (event:Event) => event.preventDefault();
    window.addEventListener('click', blockNavigation, { once: true });

    const event = new MouseEvent('click', { bubbles: true, cancelable: true, ...init });
    link.dispatchEvent(event);

    window.removeEventListener('click', blockNavigation);
    return event;
  }

  it('highlights and scrolls to the comment when the hash changes after load', async () => {
    const { el139 } = await renderActivities();

    changeHash('#comment-139');

    expect(el139.classList.contains(HIGHLIGHTED_CLASS)).toBe(true);
    expect(scrollTo).toHaveBeenCalledWith(expect.objectContaining({ behavior: 'smooth' }));
  });

  it('scrolls by the comment offset within the container, less the anchor offset', async () => {
    const { index, scroller, el139 } = await renderActivities();

    // The scroll container is offset from the viewport and already scrolled; the
    // comment's offsetParent is some other positioned ancestor, so the target must
    // be derived from the rect delta, not offsetTop. The viewport service supplies
    // the offset that seats the comment below the pinned header.
    scroller.getBoundingClientRect = () => ({ top: 100 }) as DOMRect;
    el139.getBoundingClientRect = () => ({ top: 400 }) as DOMRect;
    Object.defineProperty(scroller, 'scrollTop', { value: 50, configurable: true });
    index.viewPortService.anchorScrollOffset = () => 185;

    changeHash('#comment-139');

    // 50 (current scroll) + (400 - 100) (offset within container) - 185 (anchor offset)
    expect(scrollTo).toHaveBeenCalledWith({ top: 165, behavior: 'smooth' });
  });

  it('reacts to every hash change, moving the highlight rather than stacking it', async () => {
    const { el131, el139 } = await renderActivities();

    changeHash('#comment-139');
    expect(el139.classList.contains(HIGHLIGHTED_CLASS)).toBe(true);

    changeHash('#comment-131');
    expect(el131.classList.contains(HIGHLIGHTED_CLASS)).toBe(true);
    expect(el139.classList.contains(HIGHLIGHTED_CLASS)).toBe(false);
    expect(scrollTo).toHaveBeenCalledTimes(2);
  });

  it('routes a timestamp-link click through the hash instead of scrolling directly', async () => {
    await renderActivities();
    const controller = ctx.getController<AutoScrollingControllerType>('work-packages--activities-tab--auto-scrolling');
    const preventDefault = vi.fn();

    controller.setAnchor({
      preventDefault,
      params: { id: '139', anchorName: 'comment' },
    } as unknown as Parameters<AutoScrollingControllerType['setAnchor']>[0]);

    // It suppresses the link's native jump and lets the hash drive the scroll.
    expect(preventDefault).toHaveBeenCalled();
    expect(window.location.hash).toBe('#comment-139');
  });

  it('ignores a legacy activity anchor, which only the server can resolve', async () => {
    await renderActivities(139);

    changeHash('#activity-5');

    expect(scrollTo).not.toHaveBeenCalled();
    expect(window.location.hash).toBe('#activity-5');
  });

  it('does nothing when no element matches the hash', async () => {
    await renderActivities();

    changeHash('#comment-999');

    expect(scrollTo).not.toHaveBeenCalled();
  });

  it('stops reacting to hash changes once disconnected', async () => {
    const { el139 } = await renderActivities();
    const root = ctx.container.querySelector('[data-controller~="work-packages--activities-tab--auto-scrolling"]')!;

    root.remove();
    await ctx.nextFrame();

    changeHash('#comment-139');

    expect(scrollTo).not.toHaveBeenCalled();
    expect(el139.classList.contains(HIGHLIGHTED_CLASS)).toBe(false);
  });

  it('clears the highlight and strips the anchor on the next document click', async () => {
    const { el139 } = await renderActivities();

    changeHash('#comment-139');
    expect(el139.classList.contains(HIGHLIGHTED_CLASS)).toBe(true);

    // The reset listener is registered on a deferred tick.
    await new Promise((resolve) => setTimeout(resolve));
    document.body.click();

    expect(el139.classList.contains(HIGHLIGHTED_CLASS)).toBe(false);
    expect(window.location.hash).toBe('');
  });

  it('tears down the anchor-reset click listener on disconnect', async () => {
    await renderActivities();

    changeHash('#comment-139');
    await new Promise((resolve) => setTimeout(resolve));

    const root = ctx.container.querySelector('[data-controller~="work-packages--activities-tab--auto-scrolling"]')!;
    root.remove();
    await ctx.nextFrame();

    document.body.click();

    // The listener was bound to the controller's AbortController, so it no longer
    // mutates the URL after disconnect.
    expect(window.location.hash).toBe('#comment-139');
  });

  describe('streamed updates in an ascending list', () => {
    function autoScrollingController() {
      const el = ctx.container.querySelector('[data-controller~="work-packages--activities-tab--auto-scrolling"]')!;
      return ctx.getController<AutoScrollingControllerType>('work-packages--activities-tab--auto-scrolling', el);
    }

    // A streamed-in entry carries images that reserve no height until they load, so
    // it keeps growing and a single scroll can land just above it. The controller
    // follows the bottom while the height settles.
    it('re-asserts the bottom as the new entry grows after insertion', async () => {
      const original = globalThis.ResizeObserver;
      let resize:(() => void) | undefined;
      /* eslint-disable @typescript-eslint/no-empty-function */
      vi.stubGlobal('ResizeObserver', class {
        constructor(cb:() => void) { resize = cb; }
        observe() {}
        disconnect() {}
      });
      /* eslint-enable @typescript-eslint/no-empty-function */

      try {
        const { index, scroller } = await renderActivities();
        index.sortingAscending = true;
        Object.defineProperty(scroller, 'scrollHeight', { value: 1000, configurable: true });

        autoScrollingController().performAutoScrollingOnStreamsUpdate(true);
        expect(scrollTo).toHaveBeenCalledWith({ top: 1000, behavior: 'smooth' });

        // The entry's late content settles and the list grows taller.
        Object.defineProperty(scroller, 'scrollHeight', { value: 1400, configurable: true });
        resize?.();

        expect(scrollTo).toHaveBeenLastCalledWith({ top: 1400, behavior: 'smooth' });
      } finally {
        vi.stubGlobal('ResizeObserver', original);
      }
    });

    // Each poll opens a settle window; without teardown the prior window keeps its
    // observer alive and scrolling. A newer update, or a disconnect, must close it.
    it('tears down the prior settle window when a newer update streams in', async () => {
      const observers:{ disconnected:boolean }[] = [];
      const original = globalThis.ResizeObserver;
      /* eslint-disable @typescript-eslint/no-empty-function */
      vi.stubGlobal('ResizeObserver', class {
        state = { disconnected: false };

        constructor() { observers.push(this.state); }

        observe() {}

        disconnect() { this.state.disconnected = true; }
      });
      /* eslint-enable @typescript-eslint/no-empty-function */

      try {
        const { index, scroller } = await renderActivities();
        index.sortingAscending = true;
        Object.defineProperty(scroller, 'scrollHeight', { value: 1000, configurable: true });

        autoScrollingController().performAutoScrollingOnStreamsUpdate(true);
        autoScrollingController().performAutoScrollingOnStreamsUpdate(true);

        expect(observers).toHaveLength(2);
        expect(observers[0].disconnected).toBe(true);
        expect(observers[1].disconnected).toBe(false);
      } finally {
        vi.stubGlobal('ResizeObserver', original);
      }
    });

    it('stops following when the controller disconnects', async () => {
      const observers:{ disconnected:boolean }[] = [];
      const original = globalThis.ResizeObserver;
      /* eslint-disable @typescript-eslint/no-empty-function */
      vi.stubGlobal('ResizeObserver', class {
        state = { disconnected: false };

        constructor() { observers.push(this.state); }

        observe() {}

        disconnect() { this.state.disconnected = true; }
      });
      /* eslint-enable @typescript-eslint/no-empty-function */

      try {
        const { index, scroller } = await renderActivities();
        index.sortingAscending = true;
        Object.defineProperty(scroller, 'scrollHeight', { value: 1000, configurable: true });

        autoScrollingController().performAutoScrollingOnStreamsUpdate(true);
        expect(observers[0].disconnected).toBe(false);

        const root = ctx.container.querySelector('[data-controller~="work-packages--activities-tab--auto-scrolling"]')!;
        root.remove();
        await ctx.nextFrame();

        expect(observers[0].disconnected).toBe(true);
      } finally {
        vi.stubGlobal('ResizeObserver', original);
      }
    });

    // The follow only knows the user was at the bottom when the entry arrived. If
    // they scroll up while it settles, late growth must not yank them back down.
    it('stops following once the user scrolls during the settle window', async () => {
      let disconnected = false;
      let resize:(() => void) | undefined;
      const original = globalThis.ResizeObserver;
      /* eslint-disable @typescript-eslint/no-empty-function */
      vi.stubGlobal('ResizeObserver', class {
        constructor(cb:() => void) { resize = () => { if (!disconnected) { cb(); } }; }

        observe() {}

        disconnect() { disconnected = true; }
      });
      /* eslint-enable @typescript-eslint/no-empty-function */

      try {
        const { index, scroller } = await renderActivities();
        index.sortingAscending = true;
        Object.defineProperty(scroller, 'scrollHeight', { value: 1000, configurable: true });

        autoScrollingController().performAutoScrollingOnStreamsUpdate(true);
        expect(scrollTo).toHaveBeenCalledTimes(1);

        // The user grabs the scroll before the entry finishes growing.
        window.dispatchEvent(new WheelEvent('wheel'));

        Object.defineProperty(scroller, 'scrollHeight', { value: 1400, configurable: true });
        resize?.();

        expect(scrollTo).toHaveBeenCalledTimes(1);
        expect(scrollTo).toHaveBeenLastCalledWith({ top: 1000, behavior: 'smooth' });
      } finally {
        vi.stubGlobal('ResizeObserver', original);
      }
    });

    it('does not scroll when the list was not already at the bottom', async () => {
      const { index } = await renderActivities();
      index.sortingAscending = true;

      autoScrollingController().performAutoScrollingOnStreamsUpdate(false);

      expect(scrollTo).not.toHaveBeenCalled();
    });

    // On mobile the comment input, not the container, is the scroll target. It
    // waits for the keyboard, then follows the same way as the entry settles.
    it('follows the input into view as the new entry settles on mobile', async () => {
      const { index } = await renderActivities();
      index.sortingAscending = true;
      index.sortingDescending = false;
      index.viewPortService.isMobile = () => true;

      const input = document.createElement('div');
      input.className = 'work-packages-activities-tab-journals-new-component';
      const scrollIntoView = vi.fn();
      input.scrollIntoView = scrollIntoView;
      ctx.container
        .querySelector('[data-controller~="work-packages--activities-tab--auto-scrolling"]')!
        .appendChild(input);

      vi.useFakeTimers();
      const original = globalThis.ResizeObserver;
      let resize:(() => void) | undefined;
      /* eslint-disable @typescript-eslint/no-empty-function */
      vi.stubGlobal('ResizeObserver', class {
        constructor(cb:() => void) { resize = cb; }
        observe() {}
        disconnect() {}
      });
      /* eslint-enable @typescript-eslint/no-empty-function */

      try {
        autoScrollingController().performAutoScrollingOnStreamsUpdate(true);

        // The first scroll waits for the on-screen keyboard to settle.
        expect(scrollIntoView).not.toHaveBeenCalled();
        vi.advanceTimersByTime(300);
        expect(scrollIntoView).toHaveBeenCalledTimes(1);

        // The entry's late content settles and the list grows.
        resize?.();
        expect(scrollIntoView).toHaveBeenCalledTimes(2);
      } finally {
        vi.stubGlobal('ResizeObserver', original);
        vi.useRealTimers();
      }
    });

    // Submitting your own comment streams in an entry that grows the same way, so
    // it follows the input too, after the longer wait for the keyboard to dismiss.
    it('follows the input into view after submitting on mobile', async () => {
      const { index } = await renderActivities();
      index.sortingAscending = true;
      index.sortingDescending = false;
      index.viewPortService.isMobile = () => true;

      const input = document.createElement('div');
      input.className = 'work-packages-activities-tab-journals-new-component';
      const scrollIntoView = vi.fn();
      input.scrollIntoView = scrollIntoView;
      ctx.container
        .querySelector('[data-controller~="work-packages--activities-tab--auto-scrolling"]')!
        .appendChild(input);

      vi.useFakeTimers();
      const original = globalThis.ResizeObserver;
      let resize:(() => void) | undefined;
      /* eslint-disable @typescript-eslint/no-empty-function */
      vi.stubGlobal('ResizeObserver', class {
        constructor(cb:() => void) { resize = cb; }
        observe() {}
        disconnect() {}
      });
      /* eslint-enable @typescript-eslint/no-empty-function */

      try {
        autoScrollingController().performAutoScrollingOnFormSubmit();

        // The first scroll waits the longer keyboard-dismiss window after a send.
        vi.advanceTimersByTime(300);
        expect(scrollIntoView).not.toHaveBeenCalled();
        vi.advanceTimersByTime(500);
        expect(scrollIntoView).toHaveBeenCalledTimes(1);

        // The entry's late content settles and the list grows.
        resize?.();
        expect(scrollIntoView).toHaveBeenCalledTimes(2);
      } finally {
        vi.stubGlobal('ResizeObserver', original);
        vi.useRealTimers();
      }
    });
  });

  // The controller sets the hash only when it decides to handle a link, so the
  // hash is the clean signal of whether a click was intercepted.
  describe('in-content comment links', () => {
    it('intercepts a same-page comment link and drives it through the hash', async () => {
      await renderActivities();
      const link = addCommentBodyLink(`${window.location.origin}${window.location.pathname}#comment-139`);

      clickLink(link);

      expect(window.location.hash).toBe('#comment-139');
    });

    it('leaves a link to a different page for normal navigation', async () => {
      await renderActivities();
      const link = addCommentBodyLink(`${window.location.origin}/another/page#comment-139`);

      clickLink(link);

      expect(window.location.hash).toBe('');
    });

    it('leaves an external link untouched', async () => {
      await renderActivities();
      const link = addCommentBodyLink('https://example.test/work_packages/1/activity#comment-139');

      clickLink(link);

      expect(window.location.hash).toBe('');
    });

    it('does not hijack a modifier click meant to open a new tab', async () => {
      await renderActivities();
      const link = addCommentBodyLink(`${window.location.origin}${window.location.pathname}#comment-139`);

      clickLink(link, { metaKey: true });

      expect(window.location.hash).toBe('');
    });

    it('defers to a handler that already acted on the click', async () => {
      await renderActivities();
      const link = addCommentBodyLink(`${window.location.origin}${window.location.pathname}#comment-139`);
      // Mimics the timestamp link, whose own action preventDefaults first.
      link.addEventListener('click', (event) => event.preventDefault());

      clickLink(link);

      expect(window.location.hash).toBe('');
    });
  });
});
