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

import { ElementRef, Injector, runInInjectionContext } from '@angular/core';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { registerContextMenu } from 'core-app/shared/components/op-context-menu/testing/register-context-menu';
import { headerRowKey } from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/keyboard/navigable-rows';
import { navigableCellClassName } from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/keyboard/roving-tabindex';
import { buildTable, TableHarness } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { OpColumnsContextMenu } from './op-columns-context-menu.directive';

class TestColumnsMenu extends OpColumnsContextMenu {
  public get focusTarget():HTMLElement {
    return this.afterFocusOn;
  }
}

describe('OpColumnsContextMenu', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  const menuOn = (html:string) => {
    document.body.innerHTML = html;
    const element = document.querySelector<HTMLElement>('#trigger')!;
    const injector = Injector.create({
      providers: [
        { provide: ElementRef, useValue: new ElementRef(element) },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        ...[
          OPContextMenuService,
          WorkPackageViewColumnsService,
          WorkPackageViewSortByService,
          WorkPackageViewGroupByService,
          WorkPackageViewHierarchiesService,
          OpModalService,
          ConfirmDialogService,
        ].map((token) => ({ provide: token, useValue: {} })),
      ],
    });
    const menu = runInInjectionContext(injector, () => new TestColumnsMenu());
    menu.column = { id: 'subject' } as QueryColumn;
    menu.ngAfterViewInit();
    return menu;
  };

  it('returns focus to the sort link of its column', () => {
    const menu = menuOn('<table><thead><tr><th><div id="trigger"><a href="#" id="subject">Subject</a></div></th></tr></thead></table>');

    expect(menu.focusTarget).toBe(document.getElementById('subject'));
  });

  it('falls back to the header cell when the column has no sort link', () => {
    const menu = menuOn('<table><thead><tr><th id="cell"><div id="trigger">Subject</div></th></tr></thead></table>');

    expect(menu.focusTarget).toBe(document.getElementById('cell'));
  });

  it('falls back to its own element outside a header cell', () => {
    const menu = menuOn('<div id="trigger">Subject</div>');

    expect(menu.focusTarget).toBe(document.getElementById('trigger'));
  });
});

describe('OpColumnsContextMenu on a capability-on table', () => {
  let harness:TableHarness;
  let service:OPContextMenuService;
  let unregister:() => void;
  let page:HTMLElement;

  const nextFrame = () => new Promise<void>((resolve) => { requestAnimationFrame(() => resolve()); });

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      columns: ['id', 'subject', 'status'],
      productionMarkup: true,
      providers: [OPContextMenuService],
      configuration: { columnMenuEnabled: true, keyboardNavigationEnabled: true },
    });
    await harness.render();
    page = document.createElement('div');
    page.id = 'wrapper';
    page.textContent = 'Blank page';
    document.body.append(page);
    service = harness.injector.get(OPContextMenuService);
    unregister = registerContextMenu(service);
  });

  afterEach(async () => {
    await nextFrame();
    await nextFrame();
    await nextFrame();
    service.close();
    unregister();
    page.remove();
    await harness.destroy();
  });

  const subjectHeader = () => harness.headerCells()[1];

  const mountMenu = () => {
    const injector = Injector.create({
      providers: [
        { provide: ElementRef, useValue: new ElementRef(subjectHeader()) },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalService, useValue: {} },
        { provide: ConfirmDialogService, useValue: {} },
      ],
      parent: harness.injector,
    });
    const menu = runInInjectionContext(injector, () => new OpColumnsContextMenu());
    menu.column = harness.injector.get(WorkPackageViewColumnsService).getColumns().find((column) => column.id === 'subject')!;
    menu.table = harness.table;
    menu.ngAfterViewInit();
    return menu;
  };

  const openMenu = async () => {
    mountMenu();
    harness.table.keyboardNavigation!.focusPosition({ key: headerRowKey, cell: 1, desiredColumn: 1 });
    fireEvent.click(subjectHeader());
    await waitFor(() => expect(document.querySelector('.op-context-menu--overlay .menu-item')).toHaveFocus());
    return within(document.querySelector<HTMLElement>('.op-context-menu--overlay')!);
  };

  it('column menu: an action (move column) returns focus to the header cell, not the body', async () => {
    const overlay = await openMenu();

    fireEvent.click(overlay.getByRole('menuitem', { name: 'js.work_packages.query.move_column_right' }));

    expect(service.active).toBeNull();
    expect(subjectHeader()).toHaveFocus();
  });

  it('column menu: moving a column returns focus to its header at the new position', async () => {
    const overlay = await openMenu();
    const [, subject, status] = harness.headerCells();
    vi.spyOn(harness.injector.get(WorkPackageViewColumnsService), 'shift').mockImplementation(() => status.after(subject));

    fireEvent.click(overlay.getByRole('menuitem', { name: 'js.work_packages.query.move_column_right' }));

    expect(subject).toHaveFocus();
  });

  it('column menu: hiding a column returns focus to the previous column header', async () => {
    const overlay = await openMenu();
    const [idHeader] = harness.headerCells();

    fireEvent.click(overlay.getByRole('menuitem', { name: 'js.work_packages.query.hide_column' }));
    await new Promise((resolve) => { setTimeout(resolve); });

    expect(idHeader).toHaveFocus();
    expect(idHeader).toHaveClass(navigableCellClassName);
  });

  it('Escape immediately after opening closes the menu and returns focus to the header cell', async () => {
    mountMenu();
    harness.table.keyboardNavigation!.focusPosition({ key: headerRowKey, cell: 1, desiredColumn: 1 });
    fireEvent.click(subjectHeader());

    fireEvent.keyDown(subjectHeader(), { key: 'Escape' });

    expect(service.active).toBeNull();
    await nextFrame();
    await nextFrame();
    await nextFrame();
    expect(document.querySelector('.op-context-menu--overlay .menu-item')).toBeNull();
    expect(subjectHeader()).toHaveFocus();
  });

  it('a click outside closes the menu without returning focus to the header cell', async () => {
    await openMenu();

    fireEvent.click(page);

    expect(service.active).toBeNull();
    expect(document.body).toHaveFocus();
  });
});
