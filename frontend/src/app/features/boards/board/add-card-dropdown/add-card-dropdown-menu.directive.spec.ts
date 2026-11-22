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
import {
  Component, CUSTOM_ELEMENTS_SCHEMA, inject, InjectionToken,
} from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { type Mock } from 'vitest';
import { userEvent } from 'vitest/browser';
import { Observable, of, Subject, throwError } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import {
  OpActionMenuTriggerDirective,
} from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { BoardListComponent } from 'core-app/features/boards/board/board-list/board-list.component';
import { Board } from 'core-app/features/boards/board/board';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { AddCardDropdownMenuDirective } from './add-card-dropdown-menu.directive';
import { AddCardPermissionsService } from './add-card-permissions.service';

@Component({
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, AddCardDropdownMenuDirective],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  template: `
    <op-action-menu op-addCardDropdown label="Add card">
      <button opActionMenuTrigger type="button">Add card button</button>
    </op-action-menu>
  `,
})
class HostComponent {}

interface ListDouble {
  boardList:Pick<BoardListComponent, 'board'|'query'|'addNewCard'|'addReferenceCard'>;
  inlineCreate:Pick<WorkPackageInlineCreateService, 'canAdd'|'canReference'>;
}

const LISTS = new InjectionToken<Record<'A'|'B', ListDouble>>('list doubles');

const nextOf = <T>(queue:Observable<T>[]):Observable<T> => queue.shift() ?? throwError(() => new Error('no response queued'));

@Component({
  selector: 'op-test-list-a',
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, AddCardDropdownMenuDirective],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  template: `
    <op-action-menu op-addCardDropdown label="Add card in A">
      <button opActionMenuTrigger type="button">Add card button in A</button>
    </op-action-menu>
  `,
  providers: [
    { provide: BoardListComponent, useFactory: () => inject(LISTS).A.boardList },
    { provide: WorkPackageInlineCreateService, useFactory: () => inject(LISTS).A.inlineCreate },
  ],
})
class ListAComponent {}

@Component({
  selector: 'op-test-list-b',
  imports: [OpActionMenuComponent, OpActionMenuTriggerDirective, AddCardDropdownMenuDirective],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  template: `
    <op-action-menu op-addCardDropdown label="Add card in B">
      <button opActionMenuTrigger type="button">Add card button in B</button>
    </op-action-menu>
  `,
  providers: [
    { provide: BoardListComponent, useFactory: () => inject(LISTS).B.boardList },
    { provide: WorkPackageInlineCreateService, useFactory: () => inject(LISTS).B.inlineCreate },
  ],
})
class ListBComponent {}

@Component({
  imports: [ListAComponent, ListBComponent],
  template: '<op-test-list-a /><op-test-list-b />',
  providers: [AddCardPermissionsService],
})
class BoardHostComponent {}

describe('AddCardDropdownMenuDirective', () => {
  let fixture:ComponentFixture<unknown>|undefined;
  let boardList:Pick<BoardListComponent, 'board'|'query'> & {
    addNewCard:Mock<BoardListComponent['addNewCard']>,
    addReferenceCard:Mock<BoardListComponent['addReferenceCard']>,
  };
  let canAddLookups:number;
  let canReferenceLookups:number;

  const trigger = () => screen.getByRole('button', { name: 'Add card button' });

  const openMenu = async () => {
    await userEvent.click(trigger());
    return screen.findByRole('menu', { name: 'Add card' });
  };

  const addExisting = (menu:HTMLElement) => within(menu).getByRole('menuitem', { name: 'Add existing' });

  const addNew = (menu:HTMLElement) => within(menu).getByRole('menuitem', { name: 'Add new card' });

  interface Setup {
    canUpdate?:boolean|Observable<boolean>|(() => Observable<boolean>);
    canAdd?:Observable<boolean>;
    action?:boolean;
    canSaveQuery?:boolean;
  }

  const setup = async ({ canUpdate = true, canAdd = of(true), action = true, canSaveQuery = true }:Setup = {}) => {
    window.I18n.store({
      en: { js: { card: { add_new: 'Add new card' }, relation_buttons: { add_existing: 'Add existing' } } },
    });
    boardList = {
      addNewCard: vi.fn(),
      addReferenceCard: vi.fn(),
      board: { isAction: action } as Partial<Board> as Board,
      query: {
        updateImmediately: canSaveQuery ? {} : undefined,
        updateOrderedWorkPackages: {},
      } as Partial<QueryResource> as QueryResource,
    };
    canAddLookups = 0;
    canReferenceLookups = 0;
    const canReference = () => {
      canReferenceLookups += 1;
      if (typeof canUpdate === 'function') {
        return canUpdate();
      }
      return typeof canUpdate === 'boolean' ? of(canUpdate) : canUpdate;
    };

    await TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => window.I18n.t(key) } },
        AddCardPermissionsService,
        { provide: BoardListComponent, useValue: boardList },
        { provide: WorkPackageInlineCreateService, useValue: {
          get canAdd() {
            canAddLookups += 1;
            return canAdd;
          },
          get canReference() {
            return canReference();
          },
        } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(HostComponent);
    await fixture.whenStable();
  };

  afterEach(() => {
    fixture?.destroy();
    fixture = undefined;
  });

  it('lists adding a new card and adding an existing one', async () => {
    await setup();
    const menu = await openMenu();

    const items = within(menu).getAllByRole('menuitem');
    expect(items).toHaveLength(2);
    expect(items[0]).toHaveAccessibleName('Add new card');
    expect(items[1]).toHaveAccessibleName('Add existing');
  });

  it('adds a new card', async () => {
    await setup();
    const menu = await openMenu();

    await userEvent.click(addNew(menu));

    expect(boardList.addNewCard).toHaveBeenCalledTimes(1);
  });

  it('disables adding an existing card to an action board without the permission to update', async () => {
    await setup({ canUpdate: false });
    const menu = await openMenu();

    expect(addExisting(menu)).toHaveAttribute('aria-disabled', 'true');
    expect(addNew(menu)).not.toHaveAttribute('aria-disabled');

    await userEvent.click(addExisting(menu), { force: true });

    expect(boardList.addReferenceCard).not.toHaveBeenCalled();
  });

  it('disables adding a new card without the permission to add one', async () => {
    await setup({ canAdd: of(false) });
    const menu = await openMenu();

    expect(addNew(menu)).toHaveAttribute('aria-disabled', 'true');
    expect(addExisting(menu)).not.toHaveAttribute('aria-disabled');

    await userEvent.click(addNew(menu), { force: true });

    expect(boardList.addNewCard).not.toHaveBeenCalled();
  });

  it('waits for the permission to add a card when clicked before it loads', async () => {
    const canAdd = new Subject<boolean>();
    await setup({ canAdd });

    await userEvent.click(trigger());
    expect(screen.queryByRole('menu', { name: 'Add card' })).not.toBeInTheDocument();

    canAdd.next(true);
    const menu = await screen.findByRole('menu', { name: 'Add card' });

    expect(addNew(menu)).not.toHaveAttribute('aria-disabled');
  });

  it('allows adding an existing card to a free board whose list the user may save without the permission to update', async () => {
    await setup({ action: false, canUpdate: false });
    const menu = await openMenu();

    await userEvent.click(addExisting(menu));

    expect(boardList.addReferenceCard).toHaveBeenCalledTimes(1);
  });

  it('disables adding an existing card to a free board whose list the user may reorder but not save', async () => {
    await setup({ action: false, canSaveQuery: false });
    const menu = await openMenu();

    expect(addExisting(menu)).toHaveAttribute('aria-disabled', 'true');
  });

  it('reads the latest permission to save the list of a free board once the permission to add loads', async () => {
    const canAdd = new Subject<boolean>();
    await setup({ action: false, canAdd });

    await userEvent.click(trigger());
    boardList.query = { updateOrderedWorkPackages: {} } as Partial<QueryResource> as QueryResource;
    canAdd.next(true);
    const menu = await screen.findByRole('menu', { name: 'Add card' });

    expect(addExisting(menu)).toHaveAttribute('aria-disabled', 'true');
  });

  it('does not look up the permission to update on a free board', async () => {
    await setup({ action: false });
    await openMenu();

    expect(canReferenceLookups).toBe(0);
  });

  it('builds the items from the latest permissions once both have loaded', async () => {
    const canAdd = new Subject<boolean>();
    const canUpdate = new Subject<boolean>();
    await setup({ canAdd, canUpdate });

    await userEvent.click(trigger());
    canAdd.next(true);
    await fixture!.whenStable();
    canAdd.next(false);
    canUpdate.next(true);
    const menu = await screen.findByRole('menu', { name: 'Add card' });

    expect(addNew(menu)).toHaveAttribute('aria-disabled', 'true');
    expect(addExisting(menu)).not.toHaveAttribute('aria-disabled');
  });

  it('opens synchronously on the first click once the permissions have loaded', async () => {
    await setup();

    fireEvent.click(trigger());

    expect(screen.getByRole('menu', { name: 'Add card' })).toBeVisible();
  });

  it('opens once the permissions arrive when clicked before they load', async () => {
    const canUpdate = new Subject<boolean>();
    await setup({ canUpdate });

    await userEvent.click(trigger());
    expect(screen.queryByRole('menu', { name: 'Add card' })).not.toBeInTheDocument();

    canUpdate.next(false);
    const menu = await screen.findByRole('menu', { name: 'Add card' });

    expect(addExisting(menu)).toHaveAttribute('aria-disabled', 'true');
  });

  it('keeps the known permission and looks up a failed one again on the next opening', async () => {
    const lookups:Observable<boolean>[] = [
      throwError(() => new Error('lookup failed')),
      throwError(() => new Error('lookup failed')),
      of(true),
    ];
    await setup({ canUpdate: () => nextOf(lookups) });

    let menu = await openMenu();
    expect(addNew(menu)).not.toHaveAttribute('aria-disabled');
    expect(addExisting(menu)).toHaveAttribute('aria-disabled', 'true');

    await userEvent.keyboard('{Escape}');
    await waitFor(() => expect(screen.queryByRole('menu', { name: 'Add card' })).not.toBeInTheDocument());
    menu = await openMenu();

    expect(addNew(menu)).not.toHaveAttribute('aria-disabled');
    expect(addExisting(menu)).not.toHaveAttribute('aria-disabled');
    expect(lookups).toHaveLength(0);
    expect(canAddLookups).toBe(1);
  });

  describe('on a board with two lists', () => {
    let lookups:{ list:'A'|'B', response:Observable<boolean> }[];
    let responses:Observable<boolean>[];

    const listDouble = (name:'A'|'B'):ListDouble => ({
      boardList: {
        board: { isAction: true } as Partial<Board> as Board,
        query: {} as QueryResource,
        addNewCard: vi.fn(),
        addReferenceCard: vi.fn(),
      },
      inlineCreate: {
        canAdd: of(true),
        get canReference() {
          const response = nextOf(responses);
          lookups.push({ list: name, response });
          return response;
        },
      },
    });

    const triggerIn = (name:string) => screen.getByRole('button', { name: `Add card button in ${name}` });

    const openMenuIn = async (name:string) => {
      await userEvent.click(triggerIn(name));
      return screen.findByRole('menu', { name: `Add card in ${name}` });
    };

    const closeMenu = async () => {
      await userEvent.keyboard('{Escape}');
      await waitFor(() => expect(screen.queryByRole('menu')).not.toBeInTheDocument());
    };

    beforeEach(async () => {
      window.I18n.store({
        en: { js: { card: { add_new: 'Add new card' }, relation_buttons: { add_existing: 'Add existing' } } },
      });
      lookups = [];
      await TestBed.configureTestingModule({
        imports: [BoardHostComponent],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => window.I18n.t(key) } },
          { provide: LISTS, useValue: { A: listDouble('A'), B: listDouble('B') } },
        ],
      }).compileComponents();
    });

    const render = async () => {
      fixture = TestBed.createComponent(BoardHostComponent);
      await fixture.whenStable();
    };

    it('shares one lookup between the lists', async () => {
      responses = [of(true)];
      await render();

      const menu = await openMenuIn('B');

      expect(addExisting(menu)).not.toHaveAttribute('aria-disabled');
      expect(lookups.map(({ list }) => list)).toEqual(['A']);
    });

    it('lets every list see a failed lookup and retry it', async () => {
      const first = new Subject<boolean>();
      responses = [first, throwError(() => new Error('lookup failed')), of(true)];
      await render();

      await userEvent.click(triggerIn('B'));
      first.error(new Error('lookup failed'));
      let menu = await screen.findByRole('menu', { name: 'Add card in B' });
      expect(addExisting(menu)).toHaveAttribute('aria-disabled', 'true');
      await closeMenu();

      menu = await openMenuIn('A');
      expect(addExisting(menu)).toHaveAttribute('aria-disabled', 'true');
      await closeMenu();

      menu = await openMenuIn('B');
      expect(addExisting(menu)).not.toHaveAttribute('aria-disabled');
      await closeMenu();

      menu = await openMenuIn('A');
      expect(addExisting(menu)).not.toHaveAttribute('aria-disabled');
      expect(lookups.map(({ list }) => list)).toEqual(['A', 'A', 'B']);
    });
  });
});
