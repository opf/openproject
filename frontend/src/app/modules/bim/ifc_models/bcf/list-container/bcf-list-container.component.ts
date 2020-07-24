import {ChangeDetectionStrategy, Component, OnInit} from "@angular/core";
import {WorkPackageViewHandlerToken} from "core-app/modules/work_packages/routing/wp-view-base/event-handling/event-handler-registry";
import {WorkPackageListViewComponent} from "core-app/modules/work_packages/routing/wp-list-view/wp-list-view.component";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import {
  bimListViewIdentifier,
  bimSplitViewIdentifier,
  BimViewService
} from "core-app/modules/bim/ifc_models/pages/viewer/bim-view.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {wpDisplayCardRepresentation} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {IfcModelsDataService} from "core-app/modules/bim/ifc_models/pages/viewer/ifc-models-data.service";
import {IFCViewerService} from "core-app/modules/bim/ifc_models/ifc-viewer/ifc-viewer.service";
import {States} from "core-components/states.service";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {splitViewRoute} from "core-app/modules/work_packages/routing/split-view-routes.helper";

@Component({
  templateUrl: '/app/modules/work_packages/routing/wp-list-view/wp-list-view.component.html',
  styleUrls: ['/app/modules/work_packages/routing/wp-list-view/wp-list-view.component.sass'],
  providers: [
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
    DragAndDropService,
    CausedUpdatesService
  ],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BcfListContainerComponent extends WorkPackageListViewComponent implements OnInit {
  @InjectField() bimView:BimViewService;
  @InjectField() ifcModelsService:IfcModelsDataService;
  @InjectField() viewer:IFCViewerService;
  @InjectField() states:States;
  @InjectField() bcfApi:BcfApiService;

  public wpTableConfiguration = {
    dragAndDropEnabled: false
  };

  protected updateViewRepresentation(query:QueryResource) {
    this.wpDisplayRepresentation.setDisplayRepresentation(wpDisplayCardRepresentation);
    this.showListView = false;
  }

  public showResizerInCardView():boolean {
    if (this.noResults && this.ifcModelsService.models.length === 0) {
      return false;
    } else {
      return this.bimView.currentViewerState() === bimSplitViewIdentifier;
    }
  }

  handleWorkPackageClicked(event:{ workPackageId:string; double:boolean }) {
    // Open the viewpoint if any
    const wp = this.states.workPackages.get(event.workPackageId).value;
    if (wp && this.viewer.viewerVisible() && wp.bcfViewpoints) {
      this.viewer.showViewpoint(wp, 0);
    }

    if (event.double) {
      this.$state.go(
        splitViewRoute(this.$state),
        { workPackageId: event.workPackageId }
      );
    }
  }

  openStateLink(event:{ workPackageId:string; requestedState:string }) {
    // In case we're in a regular list without view,
    // reuse the default list behavior
    if (this.bimView.current === bimListViewIdentifier) {
      super.openStateLink(event);
      return;
    }

    // Otherwise, always open all links in the details view
    this.$state.go(
      splitViewRoute(this.$state),
      { workPackageId: event.workPackageId, focus: true }
    );
  }
}
