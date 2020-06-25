import {ChangeDetectionStrategy, Component, OnInit, AfterViewChecked} from "@angular/core";
import {WorkPackageViewHandlerToken} from "core-app/modules/work_packages/routing/wp-view-base/event-handling/event-handler-registry";
import {BcfCardViewHandlerRegistry} from "core-app/modules/bim/ifc_models/ifc-base-view/event-handler/bcf-card-view-handler-registry";
import {WorkPackageListViewComponent} from "core-app/modules/work_packages/routing/wp-list-view/wp-list-view.component";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import {bimSplitViewIdentifier, BimViewService} from "core-app/modules/bim/ifc_models/pages/viewer/bim-view.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {wpDisplayCardRepresentation, wpDisplayListRepresentation} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {IfcModelsDataService} from "core-app/modules/bim/ifc_models/pages/viewer/ifc-models-data.service";
import {WorkPackageViewColumnsService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service';

@Component({
  templateUrl: '/app/modules/work_packages/routing/wp-list-view/wp-list-view.component.html',
  styleUrls: ['/app/modules/work_packages/routing/wp-list-view/wp-list-view.component.sass'],
  providers: [
    { provide: WorkPackageViewHandlerToken, useValue: BcfCardViewHandlerRegistry },
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
    DragAndDropService,
    CausedUpdatesService
  ],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BcfListContainerComponent extends WorkPackageListViewComponent implements OnInit, AfterViewChecked {
  @InjectField() bimView:BimViewService;
  @InjectField() ifcModelsService:IfcModelsDataService;
  @InjectField() wpTableColumns:WorkPackageViewColumnsService;

  public wpTableConfiguration = {
    dragAndDropEnabled: false
  };
  
  protected updateViewRepresentation(query:QueryResource) {
    console.log('updateViewRepresentation: ', this.wpTableColumns.id, this.wpTableColumns.getColumns(), query);
    this.wpTableColumns.addColumn('bcfThumbnail', 2);

    if (this.wpDisplayRepresentation.current === null) {
      this.wpDisplayRepresentation.setDisplayRepresentation(wpDisplayCardRepresentation);
    }

    super.updateViewRepresentation(query);
  }

  protected showResizerInCardView():boolean {
    if (this.noResults && this.ifcModelsService.models.length === 0) {
      return false;
    } else {
      return this.bimView.currentViewerState() === bimSplitViewIdentifier;
    }
  }

  ngAfterViewChecked() {
    console.log('COLUMNS: ', this.wpTableColumns.getColumns());
    // this.wpTableColumns.addColumn('bcfThumbnail', 2);
  }
}
