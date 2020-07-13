import {ChangeDetectionStrategy, Component, OnInit} from "@angular/core";
import {WorkPackageViewHandlerToken} from "core-app/modules/work_packages/routing/wp-view-base/event-handling/event-handler-registry";
import {BcfCardViewHandlerRegistry} from "core-app/modules/bim/ifc_models/ifc-base-view/event-handler/bcf-card-view-handler-registry";
import {WorkPackageListViewComponent} from "core-app/modules/work_packages/routing/wp-list-view/wp-list-view.component";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import {bimSplitViewCardsIdentifier, bimSplitViewListIdentifier, BimViewService} from "core-app/modules/bim/ifc_models/pages/viewer/bim-view.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {wpDisplayCardRepresentation, wpDisplayListRepresentation} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {IfcModelsDataService} from "core-app/modules/bim/ifc_models/pages/viewer/ifc-models-data.service";
import {WorkPackageViewColumnsService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service';
import {UIRouterGlobals, UIRouter, TransitionService} from '@uirouter/core';
import {pluck, distinctUntilChanged, filter} from "rxjs/operators";

@Component({
  templateUrl: '/app/modules/bim/ifc_models/bcf/list-container/bfc-list-container.component.html',
  styleUrls: ['/app/modules/bim/ifc_models/bcf/list-container/bcf-list-container.component.sass'],
  providers: [
    { provide: WorkPackageViewHandlerToken, useValue: BcfCardViewHandlerRegistry },
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
}
