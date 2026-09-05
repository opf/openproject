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

import { Application } from '@hotwired/stimulus';
import { installElements } from '@openproject/stimulus-elements';
import { ContextualActionMenu } from 'core-common/contextual-action-menu';
import type ContextualActionMenuControllerType from './contextual-action-menu.controller';

describe('Contextual action menu controller', () => {
  const nextFrame = () => new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));

  let application:Application;
  let fixture:HTMLElement;
  let ContextualActionMenuController:typeof ContextualActionMenuControllerType;

  beforeAll(async () => {
    installElements();
    ({ default: ContextualActionMenuController } = await import('./contextual-action-menu.controller'));
  });

  beforeEach(() => {
    fixture = document.createElement('div');
    document.body.appendChild(fixture);

    application = Application.start();
    application.register('contextual-action-menu', ContextualActionMenuController);
  });

  afterEach(async () => {
    fixture.remove();
    await nextFrame();
    application.stop();
    vi.restoreAllMocks();
  });

  // The real <action-menu> element is not registered in this environment, so
  // the fixture provides an element of that tag name carrying the two members
  // the presenter reads. That keeps the controller under test honest about
  // resolving the menu through the elements blessing.
  //
  // `.menu-chrome` is a plain, non-interactive descendant of the menu itself
  // (unlike the menuitem button, which `closestInteractiveElement` already
  // excludes on its own) — it exists so a right-click on the menu's own
  // decoration, rather than on one of its items, has something to target.
  function renderCard() {
    fixture.innerHTML = `
      <article data-controller="contextual-action-menu" tabindex="0">
        <a href="/work_packages/1">Subject</a>
        <span class="plain">Story points</span>
        <action-menu>
          <span class="menu-chrome"></span>
          <button id="wp-1-menu-button" type="button" popovertarget="wp-1-menu-overlay">Actions</button>
          <anchored-position id="wp-1-menu-overlay" popover anchor="wp-1-menu-button" align="end">
            <button type="button" role="menuitem">Open details</button>
          </anchored-position>
        </action-menu>
      </article>
    `;

    const card = fixture.querySelector<HTMLElement>('article')!;
    const menu = fixture.querySelector<HTMLElement>('action-menu')!;
    const overlay = fixture.querySelector<HTMLElement>('anchored-position')!;
    const invoker = fixture.querySelector<HTMLButtonElement>('#wp-1-menu-button')!;

    Object.assign(menu, {
      overlay,
      popoverElement: overlay,
      invokerElement: invoker,
    });
    Object.assign(overlay, { anchorElement: null, update: vi.fn() });

    return {
      card, menu, overlay, invoker,
    };
  }

  // The presenter takes the overlay's `anchor` idref away for a pointer
  // invocation and expresses the pointer as an offset from the card, so these
  // two are what tell the three openings apart without measuring pixels:
  // at the pointer, at the menu's own trigger, or not retargeted at all.
  function pointerOffsetOf(overlay:HTMLElement) {
    return overlay.hasAttribute('anchor')
      ? null
      : Number(overlay.getAttribute('alignment-offset'));
  }

  function expectAnchoredAtInvoker(overlay:HTMLElement) {
    expect(overlay.getAttribute('anchor')).toBe('wp-1-menu-button');
    expect(overlay.hasAttribute('alignment-offset')).toBe(false);
  }

  // A card whose ordinary controller (backlogs-card, work-package-card, ...)
  // never rendered an action menu at all: nothing to attach a contextual
  // presentation to, so every invocation must fall through untouched.
  function renderCardWithoutMenu() {
    fixture.innerHTML = `
      <article data-controller="contextual-action-menu" tabindex="0">
        <a href="/work_packages/1">Subject</a>
        <span class="plain">Story points</span>
      </article>
    `;

    return { card: fixture.querySelector<HTMLElement>('article')! };
  }

  // Builds a detached <action-menu> subtree carrying its own overlay and
  // invoker, wired the same way renderCard's is. Used to simulate a morph or
  // turbo-stream update that replaces the action-menu subtree in place while
  // the card and its controller stay connected.
  function buildActionMenu(idSuffix:string) {
    const template = document.createElement('template');
    template.innerHTML = `
      <action-menu>
        <button id="wp-1-menu-button-${idSuffix}" type="button" popovertarget="wp-1-menu-overlay-${idSuffix}">Actions</button>
        <anchored-position id="wp-1-menu-overlay-${idSuffix}" popover anchor="wp-1-menu-button-${idSuffix}" align="end">
          <button type="button" role="menuitem">Open details</button>
        </anchored-position>
      </action-menu>
    `;

    const menu = template.content.firstElementChild as HTMLElement;
    const overlay = menu.querySelector<HTMLElement>('anchored-position')!;
    const invoker = menu.querySelector<HTMLButtonElement>('button')!;

    Object.assign(menu, {
      overlay,
      popoverElement: overlay,
      invokerElement: invoker,
    });
    Object.assign(overlay, { anchorElement: null, update: vi.fn() });

    return { menu, overlay };
  }

  // A bare contextmenu event with no button held: the ordering Windows and
  // Linux produce, where the event arrives at mouseup time and the release
  // has already happened.
  function contextMenu(target:Element, init:MouseEventInit = {}) {
    const event = new MouseEvent('contextmenu', {
      bubbles: true, cancelable: true, clientX: 50, clientY: 60, ...init,
    });
    target.dispatchEvent(event);
    return event;
  }

  // The macOS/Chrome ordering: the contextmenu event arrives at mousedown
  // time, while the button is still held, and the release follows separately.
  function rightClickPress(target:Element, init:MouseEventInit = {}) {
    target.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, button: 2, pointerType: 'mouse' }));
    target.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, button: 2 }));
    return contextMenu(target, init);
  }

  // A touch long-press: Chrome emits no `mousedown` at all before the
  // contextmenu it produces, so the gesture is a bare pointerdown followed by
  // the event while the finger is still down.
  function touchLongPress(target:Element, init:MouseEventInit = {}) {
    target.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, pointerType: 'touch' }));
    return contextMenu(target, init);
  }

  function pointerRelease(target:Element = document.body) {
    target.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, button: 2 }));
    target.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, button: 2 }));
  }

  function keydown(target:Element, key:string, init:KeyboardEventInit = {}) {
    const event = new KeyboardEvent('keydown', {
      key, bubbles: true, cancelable: true, ...init,
    });
    target.dispatchEvent(event);
    return event;
  }

  // The pointer path opens from the release, never from the contextmenu event
  // itself: a popover opened mid-gesture is light-dismissed by the trailing
  // pointerup in a real browser. This spec cannot reproduce that dismissal —
  // a synthetic contextmenu carries no pointer sequence for Chrome's
  // light-dismiss to act on — so what it pins down is the ordering the fix
  // depends on. The Selenium feature spec is the guard for the dismissal.
  it('opens the menu at the pointer on the release, not before it', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    const event = rightClickPress(card, { clientX: 120, clientY: 240 });

    expect(event.defaultPrevented).toBe(true);
    expect(overlay.matches(':popover-open')).toBe(false);

    pointerRelease(card);

    expect(overlay.matches(':popover-open')).toBe(true);
    expect(pointerOffsetOf(overlay)).toBeCloseTo(120 - card.getBoundingClientRect().left, 0);
  });

  // Windows and Linux deliver the contextmenu event at mouseup time, so no
  // further release is coming and waiting for one would never open anything.
  it('opens synchronously when the contextmenu arrives after the release', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    card.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, button: 2, pointerType: 'mouse' }));
    card.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, button: 2 }));
    pointerRelease(card);

    const event = contextMenu(card, { clientX: 120, clientY: 240 });

    expect(event.defaultPrevented).toBe(true);
    expect(overlay.matches(':popover-open')).toBe(true);
  });

  // Hardening: the release that clears the held-pointer flag is listened for
  // on the document in capture phase, so a release that never reaches this
  // element — the pointer left the card while held, or a descendant stopped
  // propagation — still leaves the flag honest. Were it stale-true, the next
  // right-click would take the asynchronous branch and wait for a release
  // that had already happened.
  it('clears the held-pointer flag from a release outside the element', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    card.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, button: 2, pointerType: 'mouse' }));
    card.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, button: 2 }));
    // The release lands elsewhere on the page and never travels through the
    // card, so only a document-level listener can see it.
    pointerRelease(document.body);

    const event = contextMenu(card, { clientX: 15, clientY: 25 });

    expect(event.defaultPrevented).toBe(true);
    expect(overlay.matches(':popover-open')).toBe(true);
  });

  // Regression: a long press must keep the browser's own menu. Suppressing it
  // and then opening a popover mid-gesture leaves a tablet user with nothing
  // at all — the trailing pointerup light-dismisses the popover, and the
  // native menu has already been prevented. AGILE-348 covers mouse and
  // keyboard; touch keeps today's behaviour untouched.
  it('leaves the native long-press menu alone for touch', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    const event = touchLongPress(card, { clientX: 30, clientY: 40 });

    expect(event.defaultPrevented).toBe(false);
    expect(overlay.matches(':popover-open')).toBe(false);

    // Nor may the release that ends the gesture open anything after the fact.
    pointerRelease(card);

    expect(overlay.matches(':popover-open')).toBe(false);
    expectAnchoredAtInvoker(overlay);
  });

  it('does not announce an invocation it declines to make for touch', async () => {
    const { card } = renderCard();
    await nextFrame();

    const origins:string[] = [];
    card.addEventListener('contextual-action-menu:beforeOpen', (event) => {
      origins.push((event as CustomEvent<{ origin:string }>).detail.origin);
    });

    touchLongPress(card);
    pointerRelease(card);

    expect(origins).toEqual([]);
  });

  // Regression: declining touch must not leave the controller stuck declining
  // — a hybrid device's next mouse right-click has to work normally.
  it('still opens for a mouse right-click after a touch long press', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    touchLongPress(card);
    pointerRelease(card);

    const event = rightClickPress(card, { clientX: 300, clientY: 400 });
    pointerRelease(card);

    expect(event.defaultPrevented).toBe(true);
    expect(overlay.matches(':popover-open')).toBe(true);
  });

  it('leaves the native context menu to interactive descendants', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    const event = contextMenu(card.querySelector('a')!);

    expect(event.defaultPrevented).toBe(false);
    expect(overlay.matches(':popover-open')).toBe(false);
  });

  // AGILE-348 QA: the menu's own trigger is the one interactive descendant
  // that must not fall through to the browser's menu — right-clicking the
  // control whose whole job is to open this menu should open this menu. It
  // opens where the trigger itself opens it, which is why the overlay keeps
  // Primer's own anchoring here.
  it('opens the menu at its trigger when the trigger is right-clicked', async () => {
    const { overlay, invoker } = renderCard();
    await nextFrame();

    const event = rightClickPress(invoker, { clientX: 300, clientY: 400 });
    pointerRelease(invoker);

    expect(event.defaultPrevented).toBe(true);
    expect(overlay.matches(':popover-open')).toBe(true);
    expectAnchoredAtInvoker(overlay);
  });

  // Following a pointer invocation, the trigger has to take its anchoring
  // back: the offsets left by the right-click on the card would otherwise drag
  // this opening away from the button it was aimed at.
  it('moves an open contextual menu back to the trigger when the trigger is right-clicked', async () => {
    const { card, overlay, invoker } = renderCard();
    await nextFrame();

    rightClickPress(card, { clientX: 120, clientY: 240 });
    pointerRelease(card);
    expect(pointerOffsetOf(overlay)).not.toBeNull();

    rightClickPress(invoker, { clientX: 300, clientY: 400 });
    pointerRelease(invoker);

    expect(overlay.matches(':popover-open')).toBe(true);
    expectAnchoredAtInvoker(overlay);
  });

  it('opens on a non-interactive descendant of the card', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    const plain = card.querySelector('.plain')!;
    const event = rightClickPress(plain);
    pointerRelease(plain);

    expect(event.defaultPrevented).toBe(true);
    expect(overlay.matches(':popover-open')).toBe(true);
  });

  // A keyboard invocation opens the menu exactly where its own show button
  // opens it (AGILE-348 QA): same menu, same card, so a second, card-relative
  // position for it would be a difference with nothing behind it. Only the
  // focus return stays contextual, which the presenter spec covers.
  it('opens at the menu trigger for Shift+F10', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    const event = keydown(card, 'F10', { shiftKey: true });

    expect(event.defaultPrevented).toBe(true);
    expect(overlay.matches(':popover-open')).toBe(true);
    expectAnchoredAtInvoker(overlay);
  });

  it('opens at the menu trigger for the Context Menu key', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    keydown(card, 'ContextMenu');

    expect(overlay.matches(':popover-open')).toBe(true);
    expectAnchoredAtInvoker(overlay);
  });

  it('swallows the contextmenu event a keyboard invocation may still emit', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    keydown(card, 'F10', { shiftKey: true });
    const event = contextMenu(card, { clientX: 500, clientY: 500 });

    expect(event.defaultPrevented).toBe(true);
    // Not re-anchored at the echo's coordinates: nothing reopened.
    expectAnchoredAtInvoker(overlay);
  });

  // Regression: suppressing the echo must not eat the next genuine
  // right-click, and must never eat one aimed at an interactive descendant
  // whose native menu the user actually wants.
  it('still opens for a real right-click after a keyboard invocation', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    keydown(card, 'F10', { shiftKey: true });
    rightClickPress(card, { clientX: 300, clientY: 400 });
    pointerRelease(card);

    expect(pointerOffsetOf(overlay)).toBeCloseTo(300 - card.getBoundingClientRect().left, 0);
    expect((overlay as unknown as { anchorElement:HTMLElement|null }).anchorElement).toBe(card);
  });

  it('never swallows a right-click aimed at an interactive descendant', async () => {
    const { card } = renderCard();
    await nextFrame();

    keydown(card, 'F10', { shiftKey: true });
    const event = contextMenu(card.querySelector('a')!);

    expect(event.defaultPrevented).toBe(false);
  });

  it('ignores keyboard invocation from a focused descendant', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    const event = keydown(card.querySelector('a')!, 'F10', { shiftKey: true });

    expect(event.defaultPrevented).toBe(false);
    expect(overlay.matches(':popover-open')).toBe(false);
  });

  it('does not present when a beforeOpen listener cancels the invocation', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    card.addEventListener('contextual-action-menu:beforeOpen', (event) => event.preventDefault());
    const event = contextMenu(card);

    expect(event.defaultPrevented).toBe(false);
    expect(overlay.matches(':popover-open')).toBe(false);
  });

  it('reports the invocation origin on the beforeOpen event', async () => {
    const { card } = renderCard();
    await nextFrame();

    const origins:string[] = [];
    card.addEventListener('contextual-action-menu:beforeOpen', (event) => {
      origins.push((event as CustomEvent<{ origin:string }>).detail.origin);
    });

    contextMenu(card);
    keydown(card, 'ContextMenu');

    expect(origins).toEqual(['pointer', 'keyboard']);
  });

  it('dispatches a cancelable pointer beforeOpen before the presenter opens', async () => {
    const { card } = renderCard();
    await nextFrame();
    const sequence:string[] = [];
    const events:CustomEvent<{ origin:string }>[] = [];
    card.addEventListener('contextual-action-menu:beforeOpen', (event) => {
      sequence.push('beforeOpen');
      events.push(event as CustomEvent<{ origin:string }>);
    });
    vi.spyOn(ContextualActionMenu.prototype, 'openAtPoint').mockImplementation(() => {
      sequence.push('present');
    });

    contextMenu(card);

    expect(sequence).toEqual(['beforeOpen', 'present']);
    expect(events).toHaveLength(1);
    expect(events[0]).toMatchObject({ cancelable: true, detail: { origin: 'pointer' } });
  });

  it.each([
    ['Context Menu key', 'ContextMenu', {}],
    ['Shift+F10', 'F10', { shiftKey: true }],
  ])('dispatches a cancelable keyboard beforeOpen before the presenter opens for %s', async (_label, key, init) => {
    const { card } = renderCard();
    await nextFrame();
    const sequence:string[] = [];
    const events:CustomEvent<{ origin:string }>[] = [];
    card.addEventListener('contextual-action-menu:beforeOpen', (event) => {
      sequence.push('beforeOpen');
      events.push(event as CustomEvent<{ origin:string }>);
    });
    vi.spyOn(ContextualActionMenu.prototype, 'openAtInvoker').mockImplementation(() => {
      sequence.push('present');
    });

    keydown(card, key, init);

    expect(sequence).toEqual(['beforeOpen', 'present']);
    expect(events).toHaveLength(1);
    expect(events[0]).toMatchObject({ cancelable: true, detail: { origin: 'keyboard' } });
  });

  it('cancellation prevents both pointer and keyboard presentation', async () => {
    const { card } = renderCard();
    await nextFrame();
    const openAtPoint = vi.spyOn(ContextualActionMenu.prototype, 'openAtPoint');
    const openAtInvoker = vi.spyOn(ContextualActionMenu.prototype, 'openAtInvoker');
    card.addEventListener('contextual-action-menu:beforeOpen', (event) => event.preventDefault());

    contextMenu(card);
    keydown(card, 'ContextMenu');

    expect(openAtPoint).not.toHaveBeenCalled();
    expect(openAtInvoker).not.toHaveBeenCalled();
  });

  it('leaves the native context menu alone when the card has no action menu', async () => {
    const { card } = renderCardWithoutMenu();
    await nextFrame();

    // A thrown exception inside a DOM event listener is reported to `window`
    // rather than re-thrown at the dispatchEvent() call site, so a crash here
    // (menuElement is null without an action-menu) would otherwise leave
    // defaultPrevented untouched and this assertion none the wiser.
    const uncaughtErrors:unknown[] = [];
    const onError = (event:ErrorEvent) => uncaughtErrors.push(event.error ?? event.message);
    window.addEventListener('error', onError);

    const event = contextMenu(card);
    await nextFrame();

    window.removeEventListener('error', onError);

    expect(event.defaultPrevented).toBe(false);
    expect(uncaughtErrors).toEqual([]);
  });

  it('leaves the native context menu alone on a right-click on the menu chrome itself', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    const event = contextMenu(card.querySelector('.menu-chrome')!);

    expect(event.defaultPrevented).toBe(false);
    expect(overlay.matches(':popover-open')).toBe(false);
  });

  // Regression: a morph or turbo-stream update can replace the action-menu
  // subtree in place while the card and its controller stay connected (no
  // disconnect/connect cycle). `menuElement` is a live querySelector, so it
  // already reports the new element on the very next access; the presenter
  // must not keep driving the detached one.
  it('rebuilds the presenter against a replaced action-menu element', async () => {
    const { card, overlay: staleOverlay } = renderCard();
    await nextFrame();

    contextMenu(card, { clientX: 10, clientY: 10 });
    expect(staleOverlay.matches(':popover-open')).toBe(true);

    const { menu: freshMenu, overlay: freshOverlay } = buildActionMenu('2');
    card.querySelector('action-menu')!.replaceWith(freshMenu);

    const event = contextMenu(card, { clientX: 20, clientY: 20 });

    expect(event.defaultPrevented).toBe(true);
    expect(freshOverlay.matches(':popover-open')).toBe(true);

    // The stale presenter was destroy()ed, not merely dropped: it restored
    // the detached overlay's attributes and gave up its pointer anchor,
    // rather than leaving both behind.
    expect(staleOverlay.getAttribute('align')).toBe('end');
    expect(staleOverlay.getAttribute('anchor')).toBe('wp-1-menu-button');
    expect(staleOverlay.hasAttribute('alignment-offset')).toBe(false);
    expect((staleOverlay as unknown as { anchorElement:HTMLElement|null }).anchorElement).toBeNull();

    expect(pointerOffsetOf(freshOverlay)).toBeCloseTo(20 - card.getBoundingClientRect().left, 0);
  });

  // Regression: `contextualMenu` must be read when the release opens the
  // menu, not captured back when the button went down — otherwise a morph
  // landing while the button is held would be invisible to it. Swapping the
  // element in exactly that gap is what makes the distinction observable.
  it('reads the presenter afresh at open time, after a swap while the button is held', async () => {
    const { card } = renderCard();
    await nextFrame();

    rightClickPress(card, { clientX: 10, clientY: 10 });

    const { menu: freshMenu, overlay: freshOverlay } = buildActionMenu('3');
    card.querySelector('action-menu')!.replaceWith(freshMenu);

    pointerRelease(card);

    expect(freshOverlay.matches(':popover-open')).toBe(true);
  });

  // Regression: a controller torn down while the button is still held must
  // leave nothing armed. `card.remove()` runs before the release, so this is
  // a real disconnect ahead of the pending open, not one that merely happens
  // to win a scheduling race in this environment.
  it('cancels a pending open if the controller disconnects before the release', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    rightClickPress(card, { clientX: 10, clientY: 10 });
    card.remove();
    await nextFrame();

    // The release still happens somewhere; nothing may act on it.
    pointerRelease();

    expect(overlay.matches(':popover-open')).toBe(false);
    expectAnchoredAtInvoker(overlay);
  });

  it('stops presenting and cleans up once the controller disconnects', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    contextMenu(card, { clientX: 10, clientY: 10 });
    expect(overlay.matches(':popover-open')).toBe(true);

    card.remove();
    await nextFrame();

    const event = contextMenu(card, { clientX: 20, clientY: 20 });

    expect(event.defaultPrevented).toBe(false);
    // restoreOverlayState only runs from the presenter's destroy(), so a
    // reverted `align` attribute is evidence disconnect() actually called it.
    expect(overlay.getAttribute('align')).toBe('end');
    expectAnchoredAtInvoker(overlay);
  });

  // Regression: `canPresent()` and the `contextualMenu` getter are not
  // evaluated atomically. `announceInvocation` dispatches `beforeOpen`
  // synchronously, so a listener that removes the action menu without
  // cancelling reaches the getter with `hasMenuElement` already false for
  // this same invocation, even though `canPresent()` passed moments earlier.
  it('does not throw when a beforeOpen listener removes the action menu without cancelling', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    // A thrown exception inside a DOM event listener is reported to `window`
    // rather than re-thrown at the call site, so this is what makes a crash
    // observable.
    const uncaughtErrors:unknown[] = [];
    const onError = (event:ErrorEvent) => uncaughtErrors.push(event.error ?? event.message);
    window.addEventListener('error', onError);

    card.addEventListener('contextual-action-menu:beforeOpen', () => {
      card.querySelector('action-menu')?.remove();
    });

    contextMenu(card);

    window.removeEventListener('error', onError);

    expect(uncaughtErrors).toEqual([]);
    expect(overlay.matches(':popover-open')).toBe(false);
    expectAnchoredAtInvoker(overlay);
  });

  // Regression: once the action menu is gone for good, `canPresent()`'s own
  // `!hasMenuElement` guard stops every later invocation from ever reaching
  // the `contextualMenu` getter again — so the invocation in which the menu
  // disappears is the last chance to retire a presenter left over from an
  // earlier, successful invocation.
  it('destroys an already-open presenter when a later beforeOpen listener removes the menu', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    // First invocation: opens for real, leaving a presenter bound to this
    // action-menu element with an open pointer anchor.
    contextMenu(card, { clientX: 10, clientY: 10 });
    expect(overlay.matches(':popover-open')).toBe(true);

    // Second invocation: canPresent() passes (the menu is still there), then
    // this listener removes that same element before the getter runs.
    card.addEventListener('contextual-action-menu:beforeOpen', () => {
      card.querySelector('action-menu')?.remove();
    });

    contextMenu(card, { clientX: 20, clientY: 20 });

    expect(overlay.getAttribute('align')).toBe('end');
    expectAnchoredAtInvoker(overlay);
  });

  // Regression: only one open may be pending at a time. A second right-click
  // arriving before the first one's release has to retire it, so the release
  // opens the menu once, at the newer position — not twice, and not at the
  // abandoned one. Counting the presenter's own calls is what distinguishes
  // "the newer open ran last" from "only the newer open ran at all".
  it('supersedes a pending open with a second right-click, keeping the later one', async () => {
    const { card } = renderCard();
    await nextFrame();

    const openAtPoint = vi.spyOn(ContextualActionMenu.prototype, 'openAtPoint');

    rightClickPress(card, { clientX: 10, clientY: 10 });
    // Still held: a second contextmenu for the same press, as a re-dispatch
    // or a browser repeating the event would produce.
    contextMenu(card, { clientX: 20, clientY: 20 });
    pointerRelease(card);

    expect(openAtPoint).toHaveBeenCalledTimes(1);
    expect(openAtPoint).toHaveBeenCalledWith(20, 20, card);
  });

  // Regression: a keyboard invocation arriving while a right-click waits for
  // its release supersedes it. The menu belongs on the card, and the
  // abandoned pointer position must not claim it back when the button comes
  // up a moment later.
  it('supersedes a pending open with a keyboard invocation', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    rightClickPress(card, { clientX: 10, clientY: 10 });
    keydown(card, 'F10', { shiftKey: true });
    pointerRelease(card);

    expect(overlay.matches(':popover-open')).toBe(true);
    expectAnchoredAtInvoker(overlay);
  });

  // Not every release is reported as a pointer event: a gesture synthesised
  // by a driver or by other page code may only produce the mouse one, and
  // the menu still has to open from it.
  it('opens on a mouseup when the release brings no pointerup', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    rightClickPress(card, { clientX: 10, clientY: 10 });
    card.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, button: 2 }));

    expect(overlay.matches(':popover-open')).toBe(true);
  });

  // Regression: a cancelled gesture (a touch or pen taken over by a scroll,
  // a drag starting) never produces the release the open is waiting for, and
  // must not be left armed for whatever release comes next.
  it('drops a pending open when the gesture is cancelled', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    rightClickPress(card, { clientX: 10, clientY: 10 });
    card.dispatchEvent(new PointerEvent('pointercancel', { bubbles: true }));
    pointerRelease(card);

    expect(overlay.matches(':popover-open')).toBe(false);
    expectAnchoredAtInvoker(overlay);
  });

  // Regression: a release that never arrives — the pointer left the window,
  // the gesture was cancelled — leaves an open armed against a gesture that
  // is over. It must not open a menu on the next, unrelated click somewhere
  // else on the page.
  it('does not open on a later unrelated click when the release never arrives', async () => {
    const { card, overlay } = renderCard();
    await nextFrame();

    rightClickPress(card, { clientX: 10, clientY: 10 });

    // A whole later gesture, elsewhere: this one's own press is what has to
    // retire the abandoned open before its release lands.
    document.body.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
    pointerRelease();

    expect(overlay.matches(':popover-open')).toBe(false);
    expectAnchoredAtInvoker(overlay);
  });
});
