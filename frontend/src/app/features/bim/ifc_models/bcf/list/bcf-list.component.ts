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

import {
  ChangeDetectionStrategy, Component, Input, OnInit,
} from '@angular/core';
import { States } from 'core-app/core/states/states.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { BcfApiService } from 'core-app/features/bim/bcf/api/bcf-api.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { BcfViewService } from 'core-app/features/bim/ifc_models/pages/viewer/bcf-view.service';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { resolveRoutingId } from 'core-app/features/work-packages/helpers/work-package-id-resolvers';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { IfcModelsDataService } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-models-data.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import {
  WorkPackageListViewComponent,
} from 'core-app/features/work-packages/routing/wp-list-view/wp-list-view.component';
import {
  WorkPackageViewColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';

@Component({
  templateUrl: './bcf-list.component.html',
  styleUrls: ['./bcf-list.component.sass'],
  providers: [
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
    CausedUpdatesService,
    // Component metadata is not inherited: this template renders <wp-table>
    // itself, so the table's drag binding needs its own scoped instance here.
    DragAndDropService,
  ],
  // The BIM/primerized layout has no equivalent of the (non-BIM) partitioned
  // page's own content-right placeholder div, so this component's own host is
  // what the <wp-resizer elementClass="..."> below measures/resizes instead.
  // Deliberately a distinct class, not the same-named one from
  host: { class: 'op-bcf-list' },
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'op-bcf-list',
  standalone: false,
})
export class BcfListComponent extends WorkPackageListViewComponent implements UntilDestroyedMixin, OnInit {
  @Input() showResizer = false;

  @LazyInject() bcfView:BcfViewService;

  @LazyInject() ifcModelsService:IfcModelsDataService;

  @LazyInject() wpTableColumns:WorkPackageViewColumnsService;

  @LazyInject() viewer:ViewerBridgeService;

  @LazyInject() states:States;

  @LazyInject() bcfApi:BcfApiService;

  public wpTableConfiguration = {
    dragAndDropEnabled: false,
  };

  public showViewPointInFlight:boolean;

  ngOnInit():void {
    super.ngOnInit();
  }

  protected updateViewRepresentation(query:QueryResource):void {
    const viewerState = this.bcfView.valueFromQuery(query);
    this.showTableView = !this.deviceService.isMobile
      && (viewerState === 'table' || viewerState === 'splitTable');
  }

  handleWorkPackageClicked(event:{ workPackageId:string; double:boolean }):void {
    const { workPackageId, double } = event;

    if (!this.showViewPointInFlight) {
      this.showViewPointInFlight = true;

      setTimeout(() => { this.showViewPointInFlight = false; }, 500);

      const wp = this.states.workPackages.get(workPackageId).value;

      if (wp && this.viewer.viewerVisible() && wp.bcfViewpoints) {
        this.viewer.showViewpoint(wp, 0);
      }
    }

    // Unlike the plain work-packages list (which opens the full view on double
    // click), BCF always opens the split view here - leaving `/bcf` would drop
    // the topic list/model toolbar. Whether the viewer pane itself is shown
    // alongside it is a layout concern (see IFCViewerPageComponent), not a
    // routing one.
    if (double || this.deviceService.isMobile) {
      this.openInSplitView(resolveRoutingId(this.states, workPackageId));
    }
  }

  // Overridden (rather than inherited as-is) because the parent's version opens
  // the full view for a 'show' link - here that would leave `/bcf` and drop the
  // topic list/model toolbar, same as handleWorkPackageClicked above.
  openStateLink(event:{ workPackageId:string; requestedState:'show'|'split' }):void {
    this.openInSplitView(resolveRoutingId(this.states, event.workPackageId));
  }
}
