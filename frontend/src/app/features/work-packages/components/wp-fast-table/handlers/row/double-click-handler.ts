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
import { StateService } from '@uirouter/core';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { States } from 'core-app/core/states/states.service';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { displayClassName } from 'core-app/shared/components/fields/display/display-field-renderer';
import { activeFieldClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { tdClassName } from '../../builders/cell-builder';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class RowDoubleClickHandler implements TableEventHandler {
  // Injections
  @LazyInject() public $state:StateService;

  @LazyInject() public states:States;

  @LazyInject() public wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() public wpTableFocus:WorkPackageViewFocusService;

  constructor(public readonly injector:Injector) {
  }

  public get EVENT():EventType {
    return 'dblclick';
  }

  public get SELECTOR() {
    return `.${tdClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tbody;
  }

  public handleEvent(view:TableEventComponent, evt:MouseEvent) {
    const target = evt.target as HTMLElement;

    // Skip clicks with modifiers
    if (isClickedWithModifier(evt)) {
      return true;
    }

    // Shortcut to any clicks within a cell
    // We don't want to handle these.
    if (target.classList.contains(`${displayClassName}`) || target.classList.contains(`${activeFieldClassName}`)) {
      debugLog('Skipping click on inner cell');
      return true;
    }

    // Locate the row from event
    const element = target.closest<HTMLElement>(this.SELECTOR)!.closest<HTMLTableRowElement>(`.${tableRowClassName}`)!;
    const wpId = element.dataset.workPackageId!;

    // Ignore links
    if (target instanceof HTMLAnchorElement || target.parentElement instanceof HTMLAnchorElement) {
      return true;
    }

    // Save the currently focused work package
    this.wpTableFocus.updateFocus(wpId);

    view.itemClicked.emit({ workPackageId: wpId, double: true });

    return false;
  }
}
