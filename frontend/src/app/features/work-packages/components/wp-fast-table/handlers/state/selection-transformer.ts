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

import { Injector } from '@angular/core';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { take, takeUntil } from 'rxjs/operators';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { paintRowSelection } from '../../builders/rows/row-selection-paint';
import { locateTableRow, scrollTableRowIntoView } from '../../helpers/wp-table-row-helpers';
import { WorkPackageTable } from '../../wp-fast-table';
import { registerWorkPackageSelectAll } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/wp-selection-keyboard';

export class SelectionTransformer {
  @LazyInject() public wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() public wpTableFocus:WorkPackageViewFocusService;

  @LazyInject() public querySpace:IsolatedQuerySpace;

  @LazyInject() public FocusHelper:FocusHelperService;

  constructor(public readonly injector:Injector,
    public readonly table:WorkPackageTable) {
    // Focus a single selection when active
    this.querySpace.tableRendered.values$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
      )
      .subscribe(() => {
        this.wpTableFocus.ifShouldFocus((wpId:string) => {
          const element = locateTableRow(wpId);
          if (element) {
            scrollTableRowIntoView(wpId);
            this.FocusHelper.focus(element);
          }
        });
      });

    this.wpTableSelection.live$()
      .pipe(takeUntil(this.querySpace.stopAllSubscriptions))
      .subscribe(() => this.paintRows());

    this.wpTableFocus.whenChanged()
      .pipe(takeUntil(this.querySpace.stopAllSubscriptions))
      .subscribe(() => this.paintRows());

    const unregisterSelectAll = registerWorkPackageSelectAll({
      root: table.tableAndTimelineContainer,
      focusSelector: '.wp-table--row',
      occurrenceSelector: '.wp-table--row[data-work-package-id][data-class-identifier]',
      rendered: () => table.renderedRows,
      selectAll: (rows, anchor) => {
        this.wpTableSelection.selectAll(rows, anchor);
        this.wpTableSelection.opContextMenu.close();
      },
    });
    this.querySpace.stopAllSubscriptions.pipe(take(1)).subscribe(unregisterSelectAll);
    this.wpTableSelection.registerDeselectAllListener();
  }

  private paintRows():void {
    this.table.tableAndTimelineContainer
      .querySelectorAll<HTMLElement>(`.${tableRowClassName}[data-work-package-id]`)
      .forEach((row) => {
        const workPackageId = row.dataset.workPackageId!;
        paintRowSelection(row, {
          selected: this.wpTableSelection.isSelected(workPackageId),
          pressed: this.wpTableFocus.isFocused(workPackageId),
        });
      });
  }
}
