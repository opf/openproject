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
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { displayClassName } from 'core-app/shared/components/fields/display/display-field-renderer';
import { activeFieldClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { KeepTabService } from '../../../wp-single-view-tabs/keep-tab/keep-tab.service';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { resolveRoutingId } from 'core-app/features/work-packages/helpers/work-package-id-resolvers';

export class RowClickHandler implements TableEventHandler {
  // Injections
  @LazyInject() public $state:StateService;

  @LazyInject() public states:States;

  @LazyInject() public keepTab:KeepTabService;

  @LazyInject() public wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() public wpTableFocus:WorkPackageViewFocusService;

  @LazyInject() public urlParams:UrlParamsService;

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
    if (target.classList.contains(`${displayClassName}`) || target.classList.contains(`${activeFieldClassName}`)) {
      debugLog('Skipping click on inner cell');
      return true;
    }

    // Locate the row from event
    const element = target.closest<HTMLTableRowElement>(this.SELECTOR)!;
    const wpId = element.dataset.workPackageId;
    const classIdentifier = element.dataset.classIdentifier!;

    if (!wpId) {
      return true;
    }

    const [index, row] = view.workPackageTable.findRenderedRow(classIdentifier);

    // Update single selection if no modifier present
    if (!(evt.ctrlKey || evt.metaKey || evt.shiftKey)) {
      this.wpTableSelection.setSelection(wpId, index);
      view.itemClicked.emit({ workPackageId: wpId, double: false });
    }

    // Multiple selection if shift present
    if (evt.shiftKey) {
      this.wpTableSelection.setMultiSelectionFrom(view.workPackageTable.renderedRows, wpId, index);
    }

    // Single selection expansion if ctrl / cmd(mac)
    if (evt.ctrlKey || evt.metaKey) {
      this.wpTableSelection.toggleRow(wpId);
    }

    view.selectionChanged.emit(this.wpTableSelection.getSelectedWorkPackageIds());

    // The current row is the last selected work package
    // not matter what other rows are (de-)selected below.
    // Thus save that row for the details view button.
    this.wpTableFocus.updateFocus(wpId);

    this.switchOpenSplitViewTo(wpId);

    return false;
  }

  /**
   * If a split view is currently open (URL has a /details/:id(/:tab) suffix), switch it
   * to the clicked row's work package. List and split view are separate, independently
   * bootstrapped Angular elements (each with their own isolated query space), so they
   * don't share WorkPackageViewFocusService - this can't be done by reacting to
   * updateFocus() from within the split view, it has to be driven from here.
   *
   * Not needed for uiRouter contexts (e.g. BIM): WorkPackageSplitViewComponent still
   * reacts to updateFocus() via $state.go there, since list and split view share one
   * component tree/injector in that case.
   */
  private switchOpenSplitViewTo(wpId:string):void {
    if (this.$state.current.name !== '') {
      return;
    }

    const details = this.urlParams.currentDetailsRouteParams();
    if (!details) {
      return;
    }

    const newRoutingId = resolveRoutingId(this.states, wpId);
    if (details.routingId === newRoutingId) {
      return;
    }

    const newPath = `${this.urlParams.basePathWithoutDetails()}/details/${newRoutingId}${details.tab ? `/${details.tab}` : ''}${window.location.search}`;
    Turbo.visit(newPath, { frame: 'content-bodyRight', action: 'advance' });
  }
}
