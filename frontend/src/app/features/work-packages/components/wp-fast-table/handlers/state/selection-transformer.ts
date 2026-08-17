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
import { takeUntil } from 'rxjs/operators';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import {
  WorkPackageViewSelectionService,
  WorkPackageViewSelectionState,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { checkedClassName, pressedClassName } from '../../builders/ui-state-link-builder';
import { locateTableRow, scrollTableRowIntoView } from '../../helpers/wp-table-row-helpers';
import { WorkPackageTable } from '../../wp-fast-table';

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

    // Update selection state
    this.wpTableSelection.live$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
      )
      .subscribe((state:WorkPackageViewSelectionState) => {
        this.renderSelectionState(state);
      });

    // Update pressed state when the focused (details-panel) WP changes
    this.wpTableFocus.whenChanged()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
      )
      .subscribe((focusedId:string) => {
        this.renderPressedState(focusedId);
      });

    this.wpTableSelection.registerSelectAllListener(() => table.renderedRows);
    this.wpTableSelection.registerDeselectAllListener();
  }

  /**
   * Update all currently visible rows to match the selection state.
   */
  private renderSelectionState(state:WorkPackageViewSelectionState) {
    const context = this.table.tableAndTimelineContainer;

    context.querySelectorAll(`.${tableRowClassName}.${checkedClassName}`).forEach((el) => el.classList.remove(checkedClassName));

    Object.entries(state.selected).forEach(([workPackageId, selected]) => {
      context.querySelectorAll(`.${tableRowClassName}[data-work-package-id="${workPackageId}"]`).forEach((el) => {
        el.classList.toggle(checkedClassName, selected);
      });
    });
  }

  /**
   * Update the pressed state to reflect the currently focused (details-panel) row.
   */
  private renderPressedState(focusedId:string|null) {
    const context = this.table.tableAndTimelineContainer;

    context.querySelectorAll(`.${tableRowClassName}.${pressedClassName}`).forEach((el) => el.classList.remove(pressedClassName));

    if (focusedId) {
      context.querySelectorAll(`.${tableRowClassName}[data-work-package-id="${focusedId}"]`).forEach((el) => {
        el.classList.add(pressedClassName);
      });
    }
  }
}
