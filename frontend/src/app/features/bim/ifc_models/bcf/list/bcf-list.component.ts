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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy, Component, Input, NgZone, OnInit,
} from '@angular/core';
import { UIRouterGlobals } from '@uirouter/core';
import { States } from 'core-app/core/states/states.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { BcfApiService } from 'core-app/features/bim/bcf/api/bcf-api.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { BcfViewService } from 'core-app/features/bim/ifc_models/pages/viewer/bcf-view.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
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
    DragAndDropService,
    CausedUpdatesService,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'op-bcf-list',
})
export class BcfListComponent extends WorkPackageListViewComponent implements UntilDestroyedMixin, OnInit {
  @Input() showResizer = false;

  @InjectField() bcfView:BcfViewService;

  @InjectField() ifcModelsService:IfcModelsDataService;

  @InjectField() wpTableColumns:WorkPackageViewColumnsService;

  @InjectField() uIRouterGlobals:UIRouterGlobals;

  @InjectField() viewer:ViewerBridgeService;

  @InjectField() states:States;

  @InjectField() bcfApi:BcfApiService;

  @InjectField() zone:NgZone;

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

  public showResizerInCardView():boolean {
    if (this.noResults && this.ifcModelsService.models.length === 0) {
      return false;
    }

    return this.bcfView.currentViewerState() === 'splitCards'
      || this.bcfView.currentViewerState() === 'splitTable';
  }

  handleWorkPackageClicked(event:{ workPackageId:string; double:boolean }):void {
    const { workPackageId, double } = event;

    if (!this.showViewPointInFlight) {
      this.showViewPointInFlight = true;

      this.zone.runOutsideAngular(() => {
        setTimeout(() => { this.showViewPointInFlight = false; }, 500);
      });

      const wp = this.states.workPackages.get(workPackageId).value;

      if (wp && this.viewer.viewerVisible() && wp.bcfViewpoints) {
        this.viewer.showViewpoint(wp, 0);
      }
    }

    if (double || this.deviceService.isMobile) {
      this.goToWpDetailState(workPackageId, this.uIRouterGlobals.params.cards);
    }
  }

  openStateLink(event:{ workPackageId:string; requestedState:string }):void {
    this.goToWpDetailState(event.workPackageId, this.uIRouterGlobals.params.cards, true);
  }

  goToWpDetailState(workPackageId:string, cards:boolean, focus?:boolean):void {
    // Show the split view when there is a viewer (browser)
    // Show only wp details when there is no viewer, plugin environment (ie: Revit)
    const stateToGo = this.viewer.shouldShowViewer
      ? splitViewRoute(this.$state)
      : 'bim.partitioned.show';
    // Passing the card param to the new state because the router doesn't keep
    // it when going to 'bim.partitioned.show'
    const params = { workPackageId, cards, focus };

    void this.$state.go(stateToGo, params);
  }
}
