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

import { TestBed } from '@angular/core/testing';
import { fireEvent, waitFor } from '@testing-library/dom';
import { computePosition, ComputePositionReturn } from '@floating-ui/dom';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { registerContextMenu } from 'core-app/shared/components/op-context-menu/testing/register-context-menu';

class TriggerMenu extends OpContextMenuHandler {
  constructor(service:OPContextMenuService, protected element:HTMLElement) {
    super(service);
    this.items = [{ linkText: 'Action', onClick: () => true }];
  }

  public computePosition(floating:HTMLElement):Promise<ComputePositionReturn> {
    return computePosition(this.element, floating);
  }
}

const nextFrame = () => new Promise<void>((resolve) => { requestAnimationFrame(() => resolve()); });

describe('OPContextMenuService', () => {
  let service:OPContextMenuService;
  let wrapper:HTMLElement;
  let trigger:HTMLButtonElement;
  let unregister:() => void;

  beforeEach(() => {
    wrapper = document.createElement('div');
    wrapper.id = 'wrapper';
    trigger = document.createElement('button');
    trigger.textContent = 'Trigger';
    wrapper.append(trigger);
    document.body.append(wrapper);

    service = TestBed.inject(OPContextMenuService);
    unregister = registerContextMenu(service);
  });

  afterEach(async () => {
    await nextFrame();
    await nextFrame();
    await nextFrame();
    service.close();
    unregister();
    wrapper.remove();
  });

  const open = () => {
    const menu = new TriggerMenu(service, trigger);
    trigger.focus();
    service.show(menu, new MouseEvent('click'));
    return menu;
  };

  const overlay = () => document.querySelector<HTMLElement>('.op-context-menu--overlay')!;

  it('Escape immediately after opening closes the menu and returns focus', async () => {
    const menu = open();
    const onOpen = vi.spyOn(menu, 'onOpen');

    fireEvent.keyDown(window, { key: 'Escape' });

    expect(service.active).toBeNull();
    expect(overlay()).not.toBeVisible();
    expect(overlay().querySelector('.dropdown')).toBeNull();
    await nextFrame();
    await nextFrame();
    await nextFrame();
    expect(onOpen).not.toHaveBeenCalled();
    expect(trigger).toHaveFocus();
  });

  it('refuses a click outside the menu while it is opening', async () => {
    open();

    fireEvent.click(wrapper);

    expect(service.active).not.toBeNull();
    await waitFor(() => expect(overlay().querySelector('.menu-item')).toHaveFocus());

    fireEvent.click(wrapper);

    expect(service.active).toBeNull();
  });

  it('Escape on an open menu closes it and returns focus to the trigger', async () => {
    open();
    await waitFor(() => expect(overlay().querySelector('.menu-item')).toHaveFocus());

    fireEvent.keyDown(window, { key: 'Escape' });

    expect(service.active).toBeNull();
    expect(trigger).toHaveFocus();
  });

  it('prevents the native menu over an open menu', async () => {
    const menu = open();
    const item = await waitFor(() => {
      const element = overlay().querySelector<HTMLElement>('.menu-item')!;
      expect(element).toHaveFocus();
      return element;
    });

    expect(fireEvent.contextMenu(item)).toBe(false);

    expect(service.active).toBe(menu);
  });

  const focusedItem = () => waitFor(() => {
    const element = overlay().querySelector<HTMLElement>('.menu-item')!;
    expect(element).toHaveFocus();
    return element;
  });

  it('keeps the native menu for a right-click on an item', async () => {
    open();
    const item = await focusedItem();

    fireEvent.pointerDown(item, { button: 2 });

    expect(fireEvent.contextMenu(item)).toBe(true);
  });

  it('prevents the native menu again once a menu reopens after a right-click', async () => {
    open();
    const item = await focusedItem();
    fireEvent.pointerDown(item, { button: 2 });
    fireEvent.contextMenu(item);

    open();
    const reopened = await focusedItem();

    expect(fireEvent.contextMenu(reopened)).toBe(false);
  });

  describe('close reason', () => {
    const openAndSpy = async () => {
      const menu = open();
      await waitFor(() => expect(overlay().querySelector('.menu-item')).toHaveFocus());
      return vi.spyOn(menu, 'onClose');
    };

    it('is escape for Escape', async () => {
      const onClose = await openAndSpy();

      fireEvent.keyDown(window, { key: 'Escape' });

      expect(onClose).toHaveBeenCalledWith(true, 'escape');
    });

    it('is action for a chosen item', async () => {
      const onClose = await openAndSpy();

      fireEvent.click(overlay().querySelector('.menu-item')!);

      expect(onClose).toHaveBeenCalledWith(false, 'action');
    });

    it('is outside for a click outside the menu', async () => {
      const onClose = await openAndSpy();

      fireEvent.click(wrapper);

      expect(onClose).toHaveBeenCalledWith(false, 'outside');
    });

    it('is scroll for a scroll outside the menu', async () => {
      const onClose = await openAndSpy();

      fireEvent.scroll(trigger);

      expect(onClose).toHaveBeenCalledWith(false, 'scroll');
    });
  });
});
