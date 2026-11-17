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

import { provideHttpClient } from '@angular/common/http';
import { TestBed } from '@angular/core/testing';
import { KebabHorizontalIconComponent } from '@openproject/octicons-angular';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { IconTriggeredContextMenuComponent } from 'core-app/shared/components/op-context-menu/icon-triggered-context-menu/icon-triggered-context-menu.component';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { Board } from '../board';
import { BoardListMenuComponent } from './board-list-menu.component';

describe('BoardListMenuComponent', () => {
  const show = vi.fn<OPContextMenuService['show']>();
  const trigger = () => screen.queryByRole('link', { name: 'js.label_open_menu' });

  beforeEach(async () => {
    show.mockClear();
    await TestBed.configureTestingModule({
      declarations: [BoardListMenuComponent, IconTriggeredContextMenuComponent],
      imports: [KebabHorizontalIconComponent],
      providers: [
        provideHttpClient(),
        States,
        IsolatedQuerySpace,
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OPContextMenuService, useValue: { show, isActive: () => false } },
      ],
    }).compileComponents();
  });

  it('reflects query permissions as a list reloads and emits removal from the menu', async () => {
    const hal = TestBed.inject(HalResourceService);
    const grid = hal.createHalResourceOfClass(GridResource, {
      options: {},
      widgets: [],
      _links: { self: { href: '/api/v3/grids/1' }, delete: { href: '/api/v3/grids/1', method: 'delete' } },
    });
    const query = hal.createHalResourceOfClass(QueryResource, {
      filters: [],
      _links: { self: { href: '/api/v3/queries/1' }, delete: { href: '/api/v3/queries/1', method: 'delete' } },
    });
    const noDeleteQuery = hal.createHalResourceOfClass(QueryResource, {
      filters: [],
      _links: { self: { href: '/api/v3/queries/1' } },
    });
    const querySpace = TestBed.inject(IsolatedQuerySpace);
    querySpace.query.putValue(noDeleteQuery);
    const board = new Board(grid);
    const fixture = TestBed.createComponent(BoardListMenuComponent);
    const remove = vi.fn<() => void>();
    fixture.componentInstance.onRemove.subscribe(remove);
    fixture.componentRef.setInput('board', board);
    await fixture.whenStable();

    expect(trigger()).toBeNull();

    querySpace.query.putValue(query);
    fireEvent.click(await screen.findByRole('link', { name: 'js.label_open_menu' }));
    await waitFor(() => expect(show).toHaveBeenCalledOnce());

    const [handler] = show.mock.calls[0];
    const [deleteItem] = handler.locals.items;
    expect(deleteItem).toMatchObject({ linkText: 'js.boards.lists.delete', disabled: false });
    deleteItem.onClick?.(new MouseEvent('click'));
    expect(remove).toHaveBeenCalledOnce();

    fixture.destroy();
    expect(querySpace.query.hasSubscribers()).toBe(false);

    const withReadyQuery = TestBed.createComponent(BoardListMenuComponent);
    withReadyQuery.componentRef.setInput('board', board);
    await withReadyQuery.whenStable();
    expect(trigger()).toBeVisible();

    querySpace.query.clear();
    await withReadyQuery.whenStable();
    expect(trigger()).toBeNull();
  });

  it('refreshes management permissions when the same board returns with a new grid', async () => {
    const hal = TestBed.inject(HalResourceService);
    const links = { self: { href: '/api/v3/grids/1' } };
    const editableGrid = hal.createHalResourceOfClass(GridResource, {
      options: {},
      widgets: [],
      _links: { ...links, delete: { href: '/api/v3/grids/1', method: 'delete' } },
    });
    const readOnlyGrid = hal.createHalResourceOfClass(GridResource, {
      options: {},
      widgets: [],
      _links: links,
    });
    const query = hal.createHalResourceOfClass(QueryResource, {
      filters: [],
      _links: { self: { href: '/api/v3/queries/1' }, delete: { href: '/api/v3/queries/1', method: 'delete' } },
    });
    const board = new Board(editableGrid);
    const boardState = TestBed.inject(States).forType<Board>('boards').get('1');
    boardState.putValue(board);
    const initialSubscribers = boardState.getSubscriberCount();
    TestBed.inject(IsolatedQuerySpace).query.putValue(query);

    const fixture = TestBed.createComponent(BoardListMenuComponent);
    fixture.componentRef.setInput('board', board);
    await fixture.whenStable();
    expect(trigger()).toBeVisible();

    board.grid = readOnlyGrid;
    boardState.putValue(board);
    await fixture.whenStable();
    expect(trigger()).toBeNull();

    board.grid = editableGrid;
    boardState.putValue(board);
    await fixture.whenStable();
    expect(trigger()).toBeVisible();

    fixture.destroy();
    expect(boardState.getSubscriberCount()).toBe(initialSubscribers);
  });
});
