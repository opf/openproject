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

import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { BoardListMenuComponent } from 'core-app/features/boards/board/board-list/board-list-menu.component';
import { Board } from 'core-app/features/boards/board/board';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

describe('BoardListMenuComponent items', () => {
  const versionItem:OpContextMenuItem = { linkText: 'Edit version', onClick: () => true };
  const deleteItem = expect.objectContaining({ linkText: 'js.boards.lists.delete', scheme: 'danger' });

  function menu(board:Partial<Board>, additional:OpContextMenuItem[] = []) {
    TestBed.configureTestingModule({
      declarations: [BoardListMenuComponent],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalService, useValue: {} },
        { provide: AuthorisationService, useValue: {} },
        { provide: IsolatedQuerySpace, useValue: { query: { value: { delete: {} } } } },
        { provide: BoardService, useValue: { canManage: () => true } },
        {
          provide: BoardActionsRegistryService,
          useValue: { get: () => ({ getAdditionalListMenuItems: () => Promise.resolve(additional) }) },
        },
      ],
    });
    const fixture = TestBed.createComponent(BoardListMenuComponent);
    fixture.componentRef.setInput('board', board);
    return fixture.componentInstance.menuItems();
  }

  it('offers only Delete list on a free board', async () => {
    expect(await menu({ isAction: false })).toEqual([deleteItem]);
  });

  it('offers only Delete list on an action board without extra items', async () => {
    expect(await menu({ isAction: true, actionAttribute: 'status' }, [])).toEqual([deleteItem]);
  });

  it('puts Delete list after the version items and a divider', async () => {
    expect(await menu({ isAction: true, actionAttribute: 'version' }, [versionItem])).toEqual([
      versionItem,
      { divider: true },
      deleteItem,
    ]);
  });
});
