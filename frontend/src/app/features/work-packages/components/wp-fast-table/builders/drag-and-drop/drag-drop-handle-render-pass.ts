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
import { States } from 'core-app/core/states/states.service';
import { DragDropHandleBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/drag-and-drop/drag-drop-handle-builder';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { PrimaryRenderPass } from '../primary-render-pass';

export class DragDropHandleRenderPass {
  @LazyInject() public states:States;

  @LazyInject() public wpTableColumns:WorkPackageViewColumnsService;

  @LazyInject() public wpTableOrder:WorkPackageViewOrderService;

  @LazyInject() notification:WorkPackageNotificationService;

  // Drag & Drop handle builder
  protected dragDropHandleBuilder = new DragDropHandleBuilder(this.injector);

  constructor(
public readonly injector:Injector,
    private table:WorkPackageTable,
    private tablePass:PrimaryRenderPass,
) {
  }

  public render() {
    if (this.table.destroyed || !this.table.configuration.dragAndDropEnabled) {
      return;
    }

    const notification = this.notification;
    const query = this.table.querySpace.query.value!;
    const { occurrences } = this.tablePass.draft;
    void this.wpTableOrder.positionsFor(query).then((positions:QueryOrder) => {
      if (this.table.destroyed || this.table.querySpace.query.value !== query) return;
      occurrences.forEach(({ workPackage, renderType, element }) => {
        // We only care for rows that are natural work packages and are not relation sub-rows
        if (!workPackage || renderType !== 'primary') {
          return;
        }

        const latestWorkPackage = this.states.workPackages.get(workPackage.id!).getValueOr(workPackage);
        const handle = this.dragDropHandleBuilder.build(latestWorkPackage, positions[workPackage.id!]);

        if (handle && element) {
          element.replaceChild(handle, element.firstElementChild!);
        }
      });
    }).catch((error:unknown) => notification.handleRawError(error));
  }
}
