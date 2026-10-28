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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
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
