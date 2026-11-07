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
import { fireEvent, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { nextFrame, nextTask } from 'core-common/testing/timing';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import {
  OpContextMenuCloseReason,
  OpContextMenuItem,
  OpContextMenuLocalsMap,
} from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OpActionMenuService } from './op-action-menu.service';

class RecordingHandler extends OpContextMenuHandler {
  readonly closeReasons:(OpContextMenuCloseReason|undefined)[] = [];

  constructor(opContextMenu:OPContextMenuService, items:OpContextMenuItem[]) {
    super(opContextMenu);
    this.items = items;
  }

  override get locals():OpContextMenuLocalsMap {
    return { items: this.items, label: 'Row actions' };
  }

  override onClose(_focus?:boolean, reason?:OpContextMenuCloseReason):void {
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

  const settle = async () => { await nextTask(); await nextFrame(); await nextFrame(); };
  const menu = () => within(document.body).getByRole('menu', { name: 'Row actions', hidden: true });
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

  it('closes the whole menu when Escape follows a submenu Escape before focus returns', async () => {
    const handler = new RecordingHandler(TestBed.inject(OPContextMenuService), items());
    service.show(handler, new KeyboardEvent('keydown'), anchor);
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
});
