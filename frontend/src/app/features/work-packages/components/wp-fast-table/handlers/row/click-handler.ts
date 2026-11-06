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

import { Injector } from '@angular/core';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { States } from 'core-app/core/states/states.service';
import {
  SelectionModifiers,
  WorkPackageViewSelectionGesturesService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';
import { displayClassName } from 'core-app/shared/components/fields/display/display-field-renderer';
import { activeFieldClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { selectionGesture } from '../state/selection-feedback';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { KeepTabService } from '../../../wp-single-view-tabs/keep-tab/keep-tab.service';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { resolveRoutingId } from 'core-app/features/work-packages/helpers/work-package-id-resolvers';

export class RowClickHandler implements TableEventHandler {
  // Injections
  @LazyInject() public keepTab:KeepTabService;

  @LazyInject() public configurationService:ConfigurationService;

  constructor(public readonly injector:Injector) {
  }

  public get EVENT():EventType {
    return 'click';
  }

  public get SELECTOR() {
    return `.${tableRowClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tbody;
  }

  public handleEvent(view:TableEventComponent, evt:MouseEvent) {
    const target = evt.target as HTMLElement;

    // Ignore links
    if (target instanceof HTMLAnchorElement || target.parentElement instanceof HTMLAnchorElement) {
      return true;
    }

    // Shortcut to any clicks within a cell
    // We don't want to handle these.
    if (this.clickActivatesCell(target) || target.classList.contains(`${activeFieldClassName}`)) {
      debugLog('Skipping click on inner cell');
      return true;
    }

    // Locate the row from event
    const element = target.closest<HTMLTableRowElement>(this.SELECTOR)!;
    const wpId = element.dataset.workPackageId;

    if (!wpId) {
      return true;
    }

    activateRow(view, wpId, element, evt);

    return false;
  }

  private clickActivatesCell(target:HTMLElement):boolean {
    return target.classList.contains(displayClassName)
      && !this.configurationService.requireDoubleClickForInlineEdit();
  }
}

/**
 * Runs the effects of activating a row: updates the selection (plain
 * activation replaces it), emits `itemClicked` without modifiers, makes the
 * row the current work package and follows it in an open split view.
 */
export function activateRow(
  view:TableEventComponent,
  wpId:string,
  element:HTMLTableRowElement,
  modifiers:SelectionModifiers = {},
):void {
  const { injector } = view.workPackageTable;

  const modified = [modifiers.ctrlKey, modifiers.metaKey, modifiers.shiftKey].some(Boolean);

  selectionGesture(view.workPackageTable, modified ? 'selection' : 'navigation', () => {
    injector.get(WorkPackageViewSelectionGesturesService)
      .handleClick(wpId, view.workPackageTable.renderedRows, modifiers, element.dataset.classIdentifier);
  });

  if (!modified) {
    view.itemClicked.emit({ workPackageId: wpId, double: false });
  }

  // The current row is the last selected work package
  // not matter what other rows are (de-)selected below.
  // Thus save that row for the details view button.
  injector.get(WorkPackageViewFocusService).updateFocus(wpId);

  switchOpenSplitViewTo(injector, wpId);
}

/**
 * If a split view is currently open (URL has a /details/:id(/:tab) suffix), switch it
 * to the clicked row's work package. List and split view are separate, independently
 * bootstrapped Angular elements (each with their own isolated query space), so they
 * don't share WorkPackageViewFocusService - this can't be done by reacting to
 * updateFocus() from within the split view, it has to be driven from here.
 */
function switchOpenSplitViewTo(injector:Injector, wpId:string):void {
  const urlParams = injector.get(UrlParamsService);
  const details = urlParams.currentDetailsRouteParams();
  if (!details) {
    return;
  }

  const newRoutingId = resolveRoutingId(injector.get(States), wpId);
  if (details.routingId === newRoutingId) {
    return;
  }

  const newPath = `${urlParams.basePathWithoutDetails()}/details/${newRoutingId}${details.tab ? `/${details.tab}` : ''}${window.location.search}`;
  Turbo.visit(newPath, { frame: 'content-bodyRight', action: 'advance' });
}
