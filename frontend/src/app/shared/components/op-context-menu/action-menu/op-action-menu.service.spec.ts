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

import '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element.js';
import { TestBed } from '@angular/core/testing';
import { createEvent, fireEvent, waitFor, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import type AnchoredPositionElement from '@openproject/primer-view-components/app/components/primer/anchored_position';
import { nextTask, settlePopover } from 'core-common/testing/timing';
import {
  OpActionMenuHost,
  OpContextMenuCloseReason,
  OpContextMenuItem,
  OpContextMenuLocalsMap,
} from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OpActionMenuService } from './op-action-menu.service';

class RecordingHandler implements OpActionMenuHost {
  readonly closeReasons:(OpContextMenuCloseReason|undefined)[] = [];

  constructor(private readonly items:OpContextMenuItem[]) {}

  get locals():OpContextMenuLocalsMap {
    return { items: this.items, label: 'Row actions' };
  }

  onClose(_focus?:boolean, reason?:OpContextMenuCloseReason):void {
    this.closeReasons.push(reason);
  }
}

describe('OpActionMenuService', () => {
  let service:OpActionMenuService;
  let anchor:HTMLButtonElement;

  const items = ():OpContextMenuItem[] => [
    { linkText: 'Open', onClick: () => true },
    {
      linkText: 'Move',
      children: [
        { linkText: 'Move up', onClick: () => true },
        { linkText: 'Move down', onClick: () => true },
      ],
    },
  ];

  const settle = settlePopover;
  const menu = () => within(document.body).getByRole('menu', { name: 'Row actions', hidden: true });
  const overlay = () => menu().closest<AnchoredPositionElement>('anchored-position')!;
  const subMenu = () => within(document.body).getByRole('menu', { name: 'Move', hidden: true });

  beforeEach(() => {
    service = TestBed.inject(OpActionMenuService);
    anchor = document.createElement('button');
    anchor.textContent = 'Actions';
    document.body.append(anchor);
  });

  afterEach(() => {
    service.close();
    anchor.remove();
  });

  it('end-aligns on the given anchor and exposes the open menu on it', async () => {
    anchor.setAttribute('aria-haspopup', 'menu');
    anchor.setAttribute('aria-expanded', 'false');

    service.show(new RecordingHandler(items()), createEvent.click(anchor), { anchor, align: 'end' });
    await settle();

    expect(overlay()).toHaveAttribute('align', 'end');
    expect(overlay().anchorElement).toBe(anchor);
    expect(anchor).toHaveAttribute('aria-expanded', 'true');
    expect(anchor).toHaveAttribute('aria-controls', menu().id);

    service.close();

    expect(anchor).toHaveAttribute('aria-expanded', 'false');
    expect(anchor).not.toHaveAttribute('aria-controls');
  });

  describe('in a scrolling container', () => {
    let scroller:HTMLElement;

    beforeEach(() => {
      scroller = document.createElement('div');
      scroller.style.cssText = 'position:fixed;top:0;left:0;width:400px;height:200px;overflow:auto';
      const spacer = document.createElement('div');
      spacer.style.height = '2000px';
      scroller.append(anchor, spacer);
      document.body.append(scroller);
    });

    afterEach(() => scroller.remove());

    // An IntersectionObserver reports in a task of its own after a frame.
    const openOnAnchor = async (handler:RecordingHandler) => {
      anchor.focus({ preventScroll: true });
      service.show(handler, createEvent.click(anchor), { anchor });
      await settle();
      await nextTask();
    };

    it('closes once its row scrolls out of view, leaving the scroll position alone', async () => {
      const handler = new RecordingHandler(items());
      await openOnAnchor(handler);
      expect(menu()).toContainElement(document.activeElement as HTMLElement);

      scroller.scrollTop = 500;

      await waitFor(() => expect(service.active).toBeNull());
      await settle();
      expect(handler.closeReasons).toEqual(['scroll']);
      expect(scroller.scrollTop).toBeCloseTo(500, 0);
    });

    it('stays open while its row is still partly in view', async () => {
      const handler = new RecordingHandler(items());
      await openOnAnchor(handler);

      scroller.scrollTop = anchor.offsetHeight / 2;
      await settle();
      await nextTask();

      expect(service.active).toBe(handler);
    });

    it('stays open when its row was never in view', async () => {
      scroller.append(anchor);
      const handler = new RecordingHandler(items());
      await openOnAnchor(handler);

      expect(service.active).toBe(handler);
    });
  });

  it('keeps the stand-in show button in view below a page taller than the viewport', async () => {
    const page = document.createElement('div');
    page.style.height = `${window.innerHeight * 2}px`;
    document.body.prepend(page);
    onTestFinished(() => page.remove());

    service.show(new RecordingHandler(items()), createEvent.click(anchor), { anchor });
    await settle();

    const standIn = overlay().closest('action-menu')!.querySelector<HTMLElement>(':scope > button')!;
    const { top, left } = standIn.getBoundingClientRect();
    expect(top).toBeGreaterThanOrEqual(0);
    expect(top).toBeLessThan(window.innerHeight);
    expect(left).toBeGreaterThanOrEqual(0);
  });

  it('opens nothing when every visible item is an empty submenu or a divider', async () => {
    const handler = new RecordingHandler([
      { divider: true },
      { linkText: 'Move', children: [{ linkText: 'Move up', hidden: true, onClick: () => true }] },
    ]);

    service.show(handler, createEvent.click(anchor), { anchor });
    await settle();

    expect(service.active).toBeNull();
    expect(within(document.body).queryByRole('menu', { hidden: true })).toBeNull();
  });

  it('opens a right-click menu on the pointer release, not before it', async () => {
    anchor.addEventListener('contextmenu', (event) => service.show(new RecordingHandler(items()), event), { once: true });
    fireEvent.contextMenu(anchor, { clientX: 40, clientY: 20, buttons: 2 });
    await settle();

    expect(overlay().matches(':popover-open')).toBe(false);

    fireEvent.pointerUp(document);
    await settle();

    expect(overlay().matches(':popover-open')).toBe(true);
  });

  it('closes only the submenu on an Escape before focus moved into it', async () => {
    const handler = new RecordingHandler(items());
    anchor.addEventListener('keydown', (event) => service.show(handler, event, { anchor }), { once: true });
    fireEvent.keyDown(anchor, { key: 'ContextMenu' });
    await settle();
    const move = within(menu()).getByRole('menuitem', { name: 'Move' });
    move.focus();

    fireEvent.keyDown(move, { key: 'ArrowRight' });
    const subOverlay = subMenu().closest('anchored-position')!;

    expect(subOverlay.matches(':popover-open')).toBe(true);

    fireEvent.keyDown(move, { key: 'Escape' });

    expect(service.active).toBe(handler);
    expect(subOverlay.matches(':popover-open')).toBe(false);
    expect(overlay().matches(':popover-open')).toBe(true);
  });

  it('closes only the submenu on an Escape from inside it', async () => {
    const handler = new RecordingHandler(items());
    anchor.addEventListener('keydown', (event) => service.show(handler, event, { anchor }), { once: true });
    fireEvent.keyDown(anchor, { key: 'ContextMenu' });
    await settle();
    within(menu()).getByRole('menuitem', { name: 'Move' }).focus();
    await userEvent.keyboard('{ArrowRight}');
    await settle();

    fireEvent.keyDown(within(subMenu()).getByRole('menuitem', { name: 'Move up' }), { key: 'Escape' });

    expect(subMenu().closest('anchored-position')!.matches(':popover-open')).toBe(false);
    expect(overlay().matches(':popover-open')).toBe(true);
    expect(service.active).toBe(handler);
  });

  it.each([
    [0, 100],
    [0, 0],
  ])('opens a right-click at (%i, %i) at the pointer', async (clientX, clientY) => {
    anchor.style.cssText = 'position: fixed; left: 300px; top: 300px';
    anchor.addEventListener('contextmenu', (event) => service.show(new RecordingHandler(items()), event), { once: true });
    fireEvent.contextMenu(anchor, { button: 2, clientX, clientY });
    await settle();

    expect(overlay().matches(':popover-open')).toBe(true);
    expect(overlay().getBoundingClientRect().left).toBe(0);
  });

  it('opens a keyboard contextmenu reported at (0, 0) at the anchor', async () => {
    anchor.style.cssText = 'position: fixed; left: 300px; top: 300px';
    anchor.addEventListener('contextmenu', (event) => service.show(new RecordingHandler(items()), event), { once: true });
    fireEvent.contextMenu(anchor, { button: 0, clientX: 0, clientY: 0 });
    await settle();

    expect(overlay().matches(':popover-open')).toBe(true);
    expect(overlay()).not.toHaveAttribute('alignment-offset');
    expect(overlay().getBoundingClientRect().left).toBeGreaterThan(0);
  });

  it('closes the whole menu when Escape follows a submenu Escape before focus returns', async () => {
    const handler = new RecordingHandler(items());
    service.show(handler, new KeyboardEvent('keydown'), { anchor });
    await settle();
    within(menu()).getByRole('menuitem', { name: 'Move' }).focus();
    await userEvent.keyboard('{ArrowRight}');
    await settle();
    const subMenuItem = within(subMenu()).getByRole('menuitem', { name: 'Move up' });

    fireEvent.keyDown(subMenuItem, { key: 'Escape' });
    fireEvent.keyDown(subMenuItem, { key: 'Escape' });

    expect(service.active).toBeNull();
    expect(handler.closeReasons).toEqual(['escape']);
  });

  it('prevents the native menu for the contextmenu event a keyboard open sends to an item', async () => {
    const handler = new RecordingHandler(items());
    service.show(handler, new KeyboardEvent('keydown'), { anchor });
    await settle();
    const item = within(menu()).getByRole('menuitem', { name: 'Open' });

    expect(fireEvent.contextMenu(item)).toBe(false);
    expect(service.active).toBe(handler);
  });

  it('leaves hidden submenu items out', async () => {
    const withHiddenChild = items();
    withHiddenChild[1].children!.push({ linkText: 'Move to top', hidden: true, onClick: () => true });
    service.show(new RecordingHandler(withHiddenChild), new KeyboardEvent('keydown'), { anchor });
    await settle();

    expect(within(subMenu()).getAllByRole('menuitem', { hidden: true }).map((item) => item.textContent?.trim()))
      .toEqual(['Move up', 'Move down']);
  });

  it('prevents the native menu while the opening key repeats on an item', async () => {
    service.show(new RecordingHandler(items()), new KeyboardEvent('keydown'), { anchor });
    await settle();
    const item = within(menu()).getByRole('menuitem', { name: 'Open' });

    expect(fireEvent.contextMenu(item)).toBe(false);
    fireEvent.keyDown(item, { key: 'ContextMenu', repeat: true });
    fireEvent.keyDown(item, { key: 'ContextMenu', repeat: true });

    expect(fireEvent.contextMenu(item)).toBe(false);
  });

  it('keeps the native menu for a deliberate Shift+F10 on an item', async () => {
    const handler = new RecordingHandler(items());
    service.show(handler, new KeyboardEvent('keydown'), { anchor });
    await settle();
    const item = within(menu()).getByRole('menuitem', { name: 'Open' });
    fireEvent.contextMenu(item);

    fireEvent.keyDown(item, { key: 'F10', shiftKey: true });

    expect(fireEvent.contextMenu(item)).toBe(true);
  });

  it('keeps the native menu in a menu opened by a right-click', async () => {
    service.show(new RecordingHandler(items()), new MouseEvent('contextmenu', { clientX: 10, clientY: 10 }), { anchor });
    await settle();

    expect(fireEvent.contextMenu(within(menu()).getByRole('menuitem', { name: 'Open' }))).toBe(true);
  });

  it('keeps the native menu for a right-click on an item', async () => {
    const handler = new RecordingHandler(items());
    service.show(handler, new KeyboardEvent('keydown'), { anchor });
    await settle();
    const item = within(menu()).getByRole('menuitem', { name: 'Open' });

    fireEvent.pointerDown(item);

    expect(fireEvent.contextMenu(item)).toBe(true);
  });
});
