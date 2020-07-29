import {ChangeDetectionStrategy, Component, OnInit} from "@angular/core";
import {WorkPackageListViewComponent} from "core-app/modules/work_packages/routing/wp-list-view/wp-list-view.component";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import {bimSplitViewCardsIdentifier, bimSplitViewListIdentifier, bimListViewIdentifier, BimViewService} from "core-app/modules/bim/ifc_models/pages/viewer/bim-view.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {IfcModelsDataService} from "core-app/modules/bim/ifc_models/pages/viewer/ifc-models-data.service";
import {WorkPackageViewColumnsService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service';
import {UIRouterGlobals} from '@uirouter/core';
import {pluck, distinctUntilChanged} from "rxjs/operators";
import {IFCViewerService} from "core-app/modules/bim/ifc_models/ifc-viewer/ifc-viewer.service";
import {States} from "core-components/states.service";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {splitViewRoute} from "core-app/modules/work_packages/routing/split-view-routes.helper";

@Component({
  templateUrl: '/app/modules/bim/ifc_models/bcf/list-container/bcf-list-container.component.html',
  styleUrls: ['/app/modules/bim/ifc_models/bcf/list-container/bcf-list-container.component.sass'],
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
  @InjectField() wpTableColumns:WorkPackageViewColumnsService;
  @InjectField() uIRouterGlobals:UIRouterGlobals;
  @InjectField() viewer:IFCViewerService;
  @InjectField() states:States;
  @InjectField() bcfApi:BcfApiService;

  public wpTableConfiguration = {
    dragAndDropEnabled: false
  };

  ngOnInit() {
    super.ngOnInit();

    // Ensure we add a bcf thumbnail column
    // until we can load the initial query
    this.wpTableColumns
          .onReady()
          .then(() => this.wpTableColumns.addColumn('bcfThumbnail', 2));

    this.uIRouterGlobals
          .params$!
          .pipe(
            this.untilDestroyed(),
            pluck('cards'),
            distinctUntilChanged(),
          )
          .subscribe((cards:boolean) => {
            console.log('PPparams$ change', cards)
            if (cards == null || cards || this.deviceService.isMobile) {
              this.showTableView = false;
            } else {
              this.showTableView = true;
            }

            this.cdRef.detectChanges();
          });
  }

  protected updateViewRepresentation(query:QueryResource) {
    // Overwrite the parent method because we are setting the view
    // above through the cards parameter (showTableView)
  }

  public showResizerInCardView():boolean {
    if (this.noResults && this.ifcModelsService.models.length === 0) {
      return false;
    } else {
      return this.bimView.currentViewerState() === bimSplitViewCardsIdentifier ||
             this.bimView.currentViewerState() === bimSplitViewListIdentifier;
    }
  }

  handleWorkPackageClicked(event:{ workPackageId:string; double:boolean }) {
    // Open the viewpoint if any
    const wp = this.states.workPackages.get(event.workPackageId).value;
    if (wp && this.viewer.viewerVisible() && wp.bcfViewpoints) {
      // this.viewer.showViewpoint(wp, 0);
    }
    console.log('splitViewRoute(this.$state): ', this.$state.params, splitViewRoute(this.$state), this.$state.current.data.baseRoute + 'details.overview');
    if (event.double) {
      this.$state.go(
        'bim.partitioned.show', // splitViewRoute(this.$state),
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
