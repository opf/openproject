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
import { OpActionMenuService } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.service';
import { headerRowKey } from 'core-app/features/work-packages/components/wp-fast-table/row-keys';
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
          OpActionMenuService,
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

describe('OpColumnsContextMenu keyboard focus', () => {
  let harness:TableHarness;
  let service:OpActionMenuService;
  let page:HTMLElement;

  const nextFrame = () => new Promise<void>((resolve) => { requestAnimationFrame(() => resolve()); });

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      columns: ['id', 'subject', 'status'],
      productionMarkup: true,
      configuration: { columnMenuEnabled: true },
    });
    await harness.render();
    page = document.createElement('div');
    page.id = 'wrapper';
    page.textContent = 'Blank page';
    document.body.append(page);
    service = harness.injector.get(OpActionMenuService);
  });

  afterEach(async () => {
    await nextFrame();
    await nextFrame();
    await nextFrame();
    service.close();
    page.remove();
    await harness.destroy();
  });

  const subjectHeader = () => harness.headerCells()[1];

  const mountMenu = (columnIndex = 1) => {
    const header = harness.headerCells()[columnIndex];
    const injector = Injector.create({
      providers: [
        { provide: ElementRef, useValue: new ElementRef(header) },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalService, useValue: {} },
        { provide: ConfirmDialogService, useValue: {} },
      ],
      parent: harness.injector,
    });
    const menu = runInInjectionContext(injector, () => new OpColumnsContextMenu());
    menu.column = harness.injector.get(WorkPackageViewColumnsService).getColumns()[columnIndex];
    menu.table = harness.table;
    menu.ngAfterViewInit();
    return menu;
  };

  const openMenu = async () => {
    mountMenu();
    harness.table.keyboardNavigation.focusPosition({ key: headerRowKey, cell: 1, desiredColumn: 1 });
    fireEvent.click(subjectHeader());
    await waitFor(() => expect(document.querySelector('#column-context-menu [role="menuitem"]')).toHaveFocus());
    return within(document.querySelector<HTMLElement>('#column-context-menu')!);
  };

  it('anchors a pointer invocation to the header even when its link was clicked', async () => {
    const menu = mountMenu();
    const show = vi.spyOn(service, 'show');
    fireEvent.click(subjectHeader().querySelector('a')!, { clientX: 25, clientY: 10 });

    expect(show).toHaveBeenCalledWith(menu, expect.any(MouseEvent), subjectHeader());
    expect(await within(document.body).findByRole('menu', { name: menu.column.name })).toBeVisible();
  });

  it('closes before confirming a change from manual sorting', async () => {
    const menu = mountMenu();
    vi.spyOn(menu.wpTableSortBy, 'isManualSortingMode', 'get').mockReturnValue(true);
    vi.spyOn(menu.wpTableSortBy, 'isSortable').mockReturnValue(true);
    const sort = vi.spyOn(menu.wpTableSortBy, 'setAsSingleSortCriteria').mockImplementation(() => undefined);
    menu.confirmDialog.confirm = vi.fn().mockImplementation(() => {
      expect(service.active).toBeNull();
      return Promise.resolve();
    });
    fireEvent.click(subjectHeader());

    fireEvent.click(await within(document.body).findByRole('menuitem', { name: 'js.work_packages.query.sort_descending' }));

    await waitFor(() => expect(sort).toHaveBeenCalledTimes(1));
  });

  it('omits sorting and grouping for an ineligible column', async () => {
    vi.spyOn(harness.injector.get(WorkPackageViewSortByService), 'isSortable').mockReturnValue(false);
    vi.spyOn(harness.injector.get(WorkPackageViewGroupByService), 'isGroupable').mockReturnValue(false);
    const overlay = await openMenu();

    expect(overlay.queryByRole('menuitem', { name: /sort_|query.group/ })).toBeNull();
  });

  it('closes before opening the columns dialog so the dialog owns focus', async () => {
    const menu = mountMenu();
    const dialog = document.createElement('button');
    document.body.append(dialog);
    menu.opModalService.show = vi.fn().mockImplementation(() => {
      expect(service.active).toBeNull();
      dialog.focus();
    });
    fireEvent.click(subjectHeader());

    fireEvent.click(await within(document.body).findByRole('menuitem', { name: 'js.work_packages.query.insert_columns' }));

    expect(dialog).toHaveFocus();
    dialog.remove();
  });

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

  it('hides the first column and focuses the next header even when it has no sort link', async () => {
    const [first, next] = harness.headerCells();
    next.querySelector('a')!.removeAttribute('id');
    const menu = mountMenu(0);
    vi.spyOn(harness.injector.get(WorkPackageViewColumnsService), 'removeColumn').mockImplementation(() => {
      menu.ngOnDestroy();
      first.remove();
    });
    harness.table.keyboardNavigation.focusPosition({ key: headerRowKey, cell: 0, desiredColumn: 0 });
    fireEvent.click(first);

    const overlay = within(document.querySelector<HTMLElement>('#column-context-menu')!);
    fireEvent.click(await overlay.findByRole('menuitem', { name: 'js.work_packages.query.hide_column' }));

    expect(next).toHaveFocus();
    expect(service.active).toBeNull();
  });

  it('Escape immediately after opening closes the menu and returns focus to the header cell', async () => {
    mountMenu();
    harness.table.keyboardNavigation.focusPosition({ key: headerRowKey, cell: 1, desiredColumn: 1 });
    fireEvent.click(subjectHeader());

    fireEvent.keyDown(subjectHeader(), { key: 'Escape' });

    expect(service.active).toBeNull();
    await nextFrame();
    await nextFrame();
    await nextFrame();
    expect(document.querySelector('#column-context-menu [role="menuitem"]')).toBeNull();
    expect(subjectHeader()).toHaveFocus();
  });

  it('a click outside closes the menu without returning focus to the header cell', async () => {
    await openMenu();

    fireEvent.pointerDown(page);

    expect(service.active).toBeNull();
    expect(document.body).toHaveFocus();
  });
});
