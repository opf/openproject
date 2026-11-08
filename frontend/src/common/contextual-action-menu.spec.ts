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

import { getAnchoredPosition } from '@primer/behaviors';
import type { MockInstance } from 'vitest';
// Importing the element registers `<anchored-position>`, so the fixture below
// gets the production accessors — including the quirk that gives this spec its
// teeth: `anchorOffset` reads its attribute as an enum (only `spacious`/`8`
// mean 8), so an arbitrary pixel offset can only reach `getAnchoredPosition` as
// a property shadowing the prototype accessor.
import type AnchoredPositionElement from '@openproject/primer-view-components/app/components/primer/anchored_position';
// Side-effect import: the type-only import above is elided, and it is loading
// the module that registers `<anchored-position>`.
import '@openproject/primer-view-components/app/components/primer/anchored_position';
import { fireEvent, waitFor } from '@testing-library/dom';
import { nextFrame, nextTask } from 'core-common/testing/timing';
import { CONTEXTUAL_ALIGN, CONTEXTUAL_SIDE, ContextualActionMenu, PointerReleaseGate } from './contextual-action-menu';

// The real <action-menu> custom element is registered by the Primer bundle,
// which the Vitest browser environment does not load. The presenter only
// touches four public members, so a structural stand-in exercises the exact
// contract without pulling in the whole component.
interface FakeMenu {
  overlay:AnchoredPositionElement;
  popoverElement:HTMLElement;
  invokerElement:HTMLButtonElement;
  ownerDocument:Document;
  contains(node:Node|null):boolean;
}

describe('ContextualActionMenu', () => {
  // The card sits at a known place well inside the viewport, so the pointer
  // offsets below are unambiguous and no viewport clamping muddies them.
  const CARD_LEFT = 100;
  const CARD_TOP = 200;
  const CARD_BOTTOM = 280;
  const POINTER_X = 150;
  const POINTER_Y = 240;

  let fixture:HTMLElement;
  let menu:FakeMenu;
  let card:HTMLElement;
  let overlay:AnchoredPositionElement;
  let popover:HTMLElement;
  let invoker:HTMLButtonElement;
  let update:MockInstance<() => void>;
  let presenter:ContextualActionMenu;

  // Where Primer would put the overlay for the anchoring currently in force.
  const anchoredPosition = () => getAnchoredPosition(overlay, overlay.anchorElement!, overlay);

  // Where Primer would put the overlay if it were anchored on a zero-size
  // point at the pointer, with no offsets at all — the position a contextual
  // invocation is supposed to produce. Both sides run the same library code,
  // so the comparison is immune to the positioned parent and to clamping.
  const positionAtPointer = (clientX:number, clientY:number) => getAnchoredPosition(
    overlay,
    new DOMRect(clientX, clientY, 0, 0),
    {
      side: CONTEXTUAL_SIDE, align: CONTEXTUAL_ALIGN, anchorOffset: 0, alignmentOffset: 0,
    },
  );

  // `hidePopover()` does not fire `toggle` synchronously — it queues a task —
  // and nothing orders that task against `requestAnimationFrame`. Waiting a
  // fixed number of frames therefore only holds where the browser happens to
  // drain the task before the frame callback, which Chrome does and Firefox
  // does not reliably do. Waiting for the event the presenter listens to is
  // both exact and one frame cheaper; the presenter registered its listener at
  // open time, so it has already run by the time this resolves.
  const closeMenu = () => new Promise<void>((resolve) => {
    const listener = (event:Event):void => {
      if ((event as ToggleEvent).newState !== 'closed') {
        return;
      }

      overlay.removeEventListener('toggle', listener);
      resolve();
    };

    overlay.addEventListener('toggle', listener);
    popover.hidePopover();
  });

  beforeEach(() => {
    fixture = document.createElement('div');
    fixture.innerHTML = `
      <article class="card" tabindex="0"
               style="position:absolute;left:${CARD_LEFT}px;top:${CARD_TOP}px;width:300px;height:${CARD_BOTTOM - CARD_TOP}px">
        <button id="wp-1-menu-button" type="button" popovertarget="wp-1-menu-overlay">Actions</button>
        <anchored-position id="wp-1-menu-overlay" popover anchor="wp-1-menu-button"
                           align="end" anchor-offset="spacious" alignment-offset="12">
          <button type="button" role="menuitem">Open details</button>
        </anchored-position>
      </article>
    `;
    document.body.appendChild(fixture);

    card = fixture.querySelector<HTMLElement>('.card')!;
    overlay = fixture.querySelector<AnchoredPositionElement>('anchored-position')!;
    popover = overlay;
    invoker = fixture.querySelector<HTMLButtonElement>('#wp-1-menu-button')!;
    update = vi.spyOn(overlay, 'update');

    menu = {
      overlay,
      popoverElement: popover,
      invokerElement: invoker,
      ownerDocument: document,
      contains: (node:Node|null) => (node ? card.contains(node) : false),
    };

    presenter = new ContextualActionMenu(menu as never);
  });

  afterEach(() => {
    presenter.destroy();
    fixture.remove();
    vi.restoreAllMocks();
  });

  it('anchors the overlay on the invoking element and opens the popover', () => {
    presenter.openAtPoint(POINTER_X, POINTER_Y, card);

    // Anchoring on the card, rather than on a point in the viewport, is what
    // makes every reposition Primer runs recompute against a rect that moves
    // with the page. See the scroll-tracking spec below.
    expect(overlay.anchorElement).toBe(card);
    // The More button's idref must be gone while the card anchors the menu:
    // the property alone would position it correctly but leave the DOM
    // claiming an anchoring that is no longer in force.
    expect(overlay.hasAttribute('anchor')).toBe(false);
    expect(overlay.getAttribute('align')).toBe(CONTEXTUAL_ALIGN);
    expect(overlay.getAttribute('side')).toBe(CONTEXTUAL_SIDE);
    expect(popover.matches(':popover-open')).toBe(true);
    expect(update).toHaveBeenCalled();
  });

  // The offsets are the whole mechanism: they are what turns an anchoring on
  // the card into a menu at the pointer. Asserting the resulting position
  // through the real `getAnchoredPosition` — rather than asserting the two
  // numbers this spec would have to derive itself — is what makes this fail if
  // either offset lands on the wrong axis or with the wrong sign.
  it('positions the menu at the pointer', () => {
    presenter.openAtPoint(POINTER_X, POINTER_Y, card);

    const wanted = positionAtPointer(POINTER_X, POINTER_Y);
    const actual = anchoredPosition();

    expect(actual.top).toBeCloseTo(wanted.top, 0);
    expect(actual.left).toBeCloseTo(wanted.left, 0);
  });

  // Regression (AGILE-348 QA): the menu used to be anchored on a synthetic
  // `position: fixed` element placed at the pointer, which never moves in
  // viewport space, so every reposition recomputed the same viewport point
  // while the card scrolled out from under it. Offsets from the card's live
  // rect are re-read on each update, so the menu goes where the card goes —
  // whether the window scrolls or a scrolling ancestor does.
  it('follows the invoking element when it moves', () => {
    presenter.openAtPoint(POINTER_X, POINTER_Y, card);
    const before = anchoredPosition();

    card.style.top = `${CARD_TOP - 50}px`;
    overlay.update();

    const after = anchoredPosition();
    expect(after.top).toBeCloseTo(before.top - 50, 0);
    expect(after.left).toBeCloseTo(before.left, 0);
  });

  it('re-anchors an already open menu instead of toggling it shut', () => {
    presenter.openAtPoint(POINTER_X, POINTER_Y, card);
    presenter.openAtPoint(POINTER_X + 60, POINTER_Y + 20, card);

    const wanted = positionAtPointer(POINTER_X + 60, POINTER_Y + 20);
    const actual = anchoredPosition();

    expect(actual.top).toBeCloseTo(wanted.top, 0);
    expect(actual.left).toBeCloseTo(wanted.left, 0);
    expect(popover.matches(':popover-open')).toBe(true);
  });

  it('restores the More button anchoring when the menu closes', async () => {
    presenter.openAtPoint(POINTER_X, POINTER_Y, card);

    // The open really did take the anchoring away, so the assertion below is
    // a restore rather than an attribute that was never touched.
    expect(overlay.hasAttribute('anchor')).toBe(false);

    await closeMenu();

    expect(overlay.getAttribute('anchor')).toBe('wp-1-menu-button');
    expect(overlay.getAttribute('align')).toBe('end');
    expect(overlay.hasAttribute('side')).toBe(false);
    expect(overlay.anchorElement).toBe(invoker);
  });

  // Regression (AGILE-348 QA): the offsets are as much a part of the borrowed
  // anchoring as the idref is. Left behind, they would shove the More button's
  // own menu to wherever the last right-click happened to land — which is the
  // exact class of bug the restore exists to prevent.
  it('restores the pointer offsets when the menu closes', async () => {
    presenter.openAtPoint(POINTER_X, POINTER_Y, card);

    expect(overlay.getAttribute('alignment-offset')).toBe(`${POINTER_X - CARD_LEFT}`);
    expect(overlay.anchorOffset).toBe(POINTER_Y - CARD_BOTTOM);

    await closeMenu();

    expect(overlay.getAttribute('alignment-offset')).toBe('12');
    // Back to the enum the attribute actually spells, which is the proof the
    // shadowing property was dropped rather than merely overwritten.
    expect(overlay.anchorOffset).toBe(8);
  });

  it('returns focus to the invoking element when the menu closes', async () => {
    presenter.openAtPoint(POINTER_X, POINTER_Y, card);
    invoker.focus();
    await closeMenu();
    await nextFrame();

    expect(document.activeElement).toBe(card);
  });

  it('leaves focus alone when something outside the menu claimed it', async () => {
    const elsewhere = document.createElement('input');
    document.body.appendChild(elsewhere);

    presenter.openAtPoint(POINTER_X, POINTER_Y, card);
    await closeMenu();
    // The restore is armed but deferred a frame, so this claims focus in the
    // window the restore exists to keep out of.
    elsewhere.focus();
    await nextFrame();

    expect(document.activeElement).toBe(elsewhere);
    elsewhere.remove();
  });

  // The restore is scheduled by the close and runs a frame later, so anything
  // that closes and reopens the popover within that frame leaves the menu
  // showing with focus legitimately on the invoker — pulling focus back to the
  // card there would empty a menu the user just opened.
  it('leaves focus alone when the menu is open again by the time the restore runs', async () => {
    presenter.openAtPoint(POINTER_X, POINTER_Y, card);
    invoker.focus();

    // Awaiting the close is what lets the close listener run — and arm its
    // restore — before the reopen.
    await closeMenu();

    popover.showPopover();
    await nextFrame();

    expect(document.activeElement).toBe(invoker);
  });

  it('restores overlay state on destroy', () => {
    presenter.openAtPoint(POINTER_X, POINTER_Y, card);
    presenter.destroy();

    expect(overlay.getAttribute('anchor')).toBe('wp-1-menu-button');
    expect(overlay.getAttribute('alignment-offset')).toBe('12');
    expect(overlay.anchorOffset).toBe(8);
  });

  describe('opening at the menu invoker', () => {
    it('opens the popover without touching the anchoring', () => {
      presenter.openAtInvoker(card);

      // Primer's own anchoring is left in force, so this opening lands exactly
      // where the More button lands it.
      expect(overlay.getAttribute('anchor')).toBe('wp-1-menu-button');
      expect(overlay.anchorElement).toBe(invoker);
      expect(overlay.getAttribute('align')).toBe('end');
      expect(overlay.hasAttribute('side')).toBe(false);
      expect(overlay.getAttribute('alignment-offset')).toBe('12');
      expect(overlay.anchorOffset).toBe(8);
      expect(popover.matches(':popover-open')).toBe(true);
    });

    it('still returns focus to the invoking element when the menu closes', async () => {
      presenter.openAtInvoker(card);
      invoker.focus();
      await closeMenu();
      await nextFrame();

      expect(document.activeElement).toBe(card);
    });

    // Nothing was overridden, so the close has nothing to put back. A restore
    // running here would re-apply state captured by some earlier invocation
    // and quietly overwrite whatever the page has set since.
    it('leaves the anchoring alone when the menu closes', async () => {
      presenter.openAtInvoker(card);

      // Set *after* the open: state captured at open time would be re-applied
      // over this on close, quietly reverting a change the page made while the
      // menu was up.
      overlay.setAttribute('align', 'center');

      await closeMenu();

      expect(overlay.getAttribute('align')).toBe('center');
    });

    // Taking over a menu that a right-click left open: its borrowed anchoring
    // has to go before this opening claims the invoker's position, or the
    // pointer offsets would silently drag the menu away from the button.
    it('undoes a contextual invocation it takes over from', () => {
      presenter.openAtPoint(POINTER_X, POINTER_Y, card);
      presenter.openAtInvoker(card);

      expect(overlay.getAttribute('anchor')).toBe('wp-1-menu-button');
      expect(overlay.anchorElement).toBe(invoker);
      expect(overlay.getAttribute('align')).toBe('end');
      expect(overlay.getAttribute('alignment-offset')).toBe('12');
      expect(overlay.anchorOffset).toBe(8);
      expect(popover.matches(':popover-open')).toBe(true);
    });
  });

  describe('fitting the pointer position', () => {
    const rect = () => overlay.getBoundingClientRect();
    const expectRect = (check:(r:DOMRect) => void) => waitFor(() => check(rect()));

    it('opens below and to the right of the pointer when it fits', async () => {
      presenter.openAtPoint(100, 100, card);

      await expectRect((r) => {
        expect(Math.round(r.left)).toBe(100);
        expect(Math.round(r.top)).toBe(100);
      });
      expect(overlay).toHaveAttribute('allow-out-of-bounds');
    });

    it('opens above the pointer when the menu does not fit below it', async () => {
      overlay.style.height = '200px';
      const y = window.innerHeight - 50;

      presenter.openAtPoint(100, y, card);

      await expectRect((r) => {
        expect(Math.round(r.left)).toBe(100);
        expect(Math.round(r.bottom)).toBe(y);
      });
    });

    it('opens to the left of the pointer when the menu does not fit to its right', async () => {
      overlay.style.width = '240px';
      const x = window.innerWidth - 50;

      presenter.openAtPoint(x, 100, card);

      await expectRect((r) => {
        expect(Math.round(r.right)).toBe(x);
        expect(Math.round(r.top)).toBe(100);
      });
    });

    it('pins the menu to the viewport bottom when it fits neither below nor above the pointer', async () => {
      // AP-4: a menu taller than the space on either side of the pointer. Primer would walk to
      // outside-right and reinterpret the offsets; the menu must stay under the pointer's x.
      const height = Math.round(window.innerHeight * 0.8);
      overlay.style.height = `${height}px`;

      presenter.openAtPoint(100, Math.round(window.innerHeight / 2), card);

      await expectRect((r) => {
        expect(Math.round(r.left)).toBe(100);
        expect(Math.round(r.bottom)).toBe(window.innerHeight);
      });
    });

    it('refits when the open menu grows past the viewport edge', async () => {
      overlay.style.cssText = 'min-width: 0; width: 20px';
      const x = window.innerWidth - 50;
      presenter.openAtPoint(x, 100, card);
      await expectRect((r) => expect(Math.round(r.left)).toBe(x));

      overlay.style.width = '240px';
      await nextFrame();
      await nextTask();

      expect(Number(overlay.getAttribute('alignment-offset'))).toBe(x - 240 - CARD_LEFT);
      await expectRect((r) => expect(Math.round(r.right)).toBeLessThanOrEqual(window.innerWidth));
    });

    it('refits the open menu when the window resizes', () => {
      overlay.style.cssText = 'min-width: 0; width: 40px';
      presenter.openAtPoint(100, 100, card);
      vi.spyOn(window, 'innerWidth', 'get').mockReturnValue(120);

      fireEvent.resize(window);

      expect(Number(overlay.getAttribute('alignment-offset'))).toBe(100 - 40 - CARD_LEFT);
    });

    it('keeps a flipped menu inside a viewport that shrank under it', () => {
      overlay.style.cssText = 'min-width: 0; width: 240px; height: 200px';
      const innerWidth = vi.spyOn(window, 'innerWidth', 'get').mockReturnValue(1000);
      const innerHeight = vi.spyOn(window, 'innerHeight', 'get').mockReturnValue(800);
      presenter.openAtPoint(700, 550, card);

      innerWidth.mockReturnValue(600);
      innerHeight.mockReturnValue(400);
      fireEvent.resize(window);

      const left = CARD_LEFT + Number(overlay.getAttribute('alignment-offset'));
      const top = card.getBoundingClientRect().bottom + overlay.anchorOffset;
      expect(left + 240).toBeLessThanOrEqual(600);
      expect(top + 200).toBeLessThanOrEqual(400);
    });

    describe('while the page scrolls', () => {
      const menuTop = () => card.getBoundingClientRect().bottom + overlay.anchorOffset;
      const scrollCardTo = (top:number) => {
        card.style.top = `${top}px`;
        fireEvent.scroll(window);
      };

      beforeEach(() => {
        overlay.style.cssText = 'min-width: 0; width: 240px; height: 200px';
        vi.spyOn(window, 'innerWidth', 'get').mockReturnValue(1000);
      });

      it('follows the invoking element where the menu still fits', () => {
        vi.spyOn(window, 'innerHeight', 'get').mockReturnValue(800);
        presenter.openAtPoint(POINTER_X, POINTER_Y, card);
        const opened = menuTop();

        scrollCardTo(CARD_TOP + 50);

        expect(menuTop()).toBeCloseTo(opened + 50, 0);
      });

      it('keeps a menu fitted above the pointer inside the top of the viewport', () => {
        vi.spyOn(window, 'innerHeight', 'get').mockReturnValue(300);
        presenter.openAtPoint(POINTER_X, POINTER_Y, card);

        scrollCardTo(CARD_TOP - 100);

        expect(menuTop()).toBeGreaterThanOrEqual(0);
      });

      it('keeps a menu below the pointer inside the bottom of the viewport', () => {
        vi.spyOn(window, 'innerHeight', 'get').mockReturnValue(800);
        presenter.openAtPoint(POINTER_X, POINTER_Y, card);

        scrollCardTo(600);

        expect(menuTop() + 200).toBeLessThanOrEqual(800);
      });

      it('stops following the scroll once the menu closed', async () => {
        vi.spyOn(window, 'innerHeight', 'get').mockReturnValue(800);
        presenter.openAtPoint(POINTER_X, POINTER_Y, card);
        await closeMenu();
        update.mockClear();

        scrollCardTo(600);

        expect(update).not.toHaveBeenCalled();
      });
    });

    it('stops refitting once the presenter is destroyed', async () => {
      overlay.style.cssText = 'min-width: 0; width: 20px';
      presenter.openAtPoint(window.innerWidth - 50, 100, card);
      await nextFrame();
      await nextTask();
      presenter.destroy();

      overlay.style.width = '240px';
      vi.spyOn(window, 'innerWidth', 'get').mockReturnValue(120);
      fireEvent.resize(window);
      await nextFrame();
      await nextTask();

      expect(overlay.getAttribute('alignment-offset')).toBe('12');
    });

    it('restores allow-out-of-bounds with the rest of the anchoring when the menu closes', async () => {
      presenter.openAtPoint(100, 100, card);
      expect(overlay).toHaveAttribute('allow-out-of-bounds');

      await closeMenu();

      expect(overlay).not.toHaveAttribute('allow-out-of-bounds');
    });
  });

  describe('opening at an anchor', () => {
    it('anchors on the given element with the requested alignment', () => {
      presenter.openAtAnchor(card, { align: 'end' });

      expect(overlay.anchorElement).toBe(card);
      expect(overlay.hasAttribute('anchor')).toBe(false);
      expect(overlay.getAttribute('align')).toBe('end');
      expect(overlay.getAttribute('side')).toBe('outside-bottom');
      expect(overlay.hasAttribute('alignment-offset')).toBe(false);
      // The overlay's own gap (`anchor-offset="spacious"`) stays in force.
      expect(overlay.anchorOffset).toBe(8);
      expect(popover.matches(':popover-open')).toBe(true);
    });

    it('stops refitting a pointer open it takes over from', () => {
      presenter.openAtPoint(POINTER_X, POINTER_Y, card);
      presenter.openAtAnchor(invoker, { align: 'end' });

      fireEvent.resize(window);

      expect(overlay).not.toHaveAttribute('alignment-offset');
      expect(overlay).not.toHaveAttribute('allow-out-of-bounds');
      expect(overlay.anchorElement).toBe(invoker);
    });

    it('restores the original anchoring when the menu closes', async () => {
      presenter.openAtAnchor(card, { align: 'end' });

      await closeMenu();

      expect(overlay.getAttribute('anchor')).toBe('wp-1-menu-button');
      expect(overlay.getAttribute('align')).toBe('end');
      expect(overlay.getAttribute('alignment-offset')).toBe('12');
      expect(overlay.hasAttribute('side')).toBe(false);
      expect(overlay.anchorElement).toBe(invoker);
    });
  });
});

describe('PointerReleaseGate', () => {
  let controller:AbortController;

  beforeEach(() => {
    controller = new AbortController();
  });

  afterEach(() => {
    controller.abort();
  });

  it('runs the open on the release that ends the gesture', () => {
    const gate = new PointerReleaseGate(document, controller.signal);
    const open = vi.fn();

    gate.press();
    gate.openOnRelease(open);
    expect(open).not.toHaveBeenCalled();
    expect(gate.pointerIsDown).toBe(true);

    fireEvent.pointerUp(document);

    expect(open).toHaveBeenCalledTimes(1);
    expect(gate.pointerIsDown).toBe(false);
  });

  it('drops a pending open on the next press', () => {
    const gate = new PointerReleaseGate(document, controller.signal);
    const open = vi.fn();

    gate.press();
    gate.openOnRelease(open);
    fireEvent.pointerDown(document);
    fireEvent.pointerUp(document);

    expect(open).not.toHaveBeenCalled();
  });
});
