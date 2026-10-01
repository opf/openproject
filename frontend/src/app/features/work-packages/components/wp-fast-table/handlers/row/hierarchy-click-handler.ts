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
import { States } from 'core-app/core/states/states.service';
import { TableEventComponent, TableEventHandler } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { ClickOrEnterHandler } from '../click-or-enter-handler';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class HierarchyClickHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  @LazyInject() public states:States;

  @LazyInject() public wpTableHierarchies:WorkPackageViewHierarchiesService;

  constructor(public readonly injector:Injector) {
    super();
  }

  public get EVENT():EventType {
    return 'click';
  }

  public get SELECTOR() {
    return '.wp-table--hierarchy-indicator';
  }

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tbody;
  }

  public processEvent(table:WorkPackageTable, evt:MouseEvent|KeyboardEvent):void {
    const target = evt.target as HTMLElement;

    // Locate the row from event
    const element = target.closest<HTMLElement>(`.${tableRowClassName}`);
    const wpId = element?.dataset.workPackageId ?? '';

    this.wpTableHierarchies.toggle(wpId);

    evt.stopImmediatePropagation();
    evt.preventDefault();
  }
}
