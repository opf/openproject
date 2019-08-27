import {Injectable, Injector} from "@angular/core";
import {OpModalService} from "app/components/op-modals/op-modal.service";
import {AddGridWidgetModal} from "app/modules/grids/widgets/add/add.modal";
import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {GridArea} from "app/modules/grids/areas/grid-area";
import {HalResourceService} from "app/modules/hal/services/hal-resource.service";
import {GridWidgetArea} from "core-app/modules/grids/areas/grid-widget-area";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {GridDragAndDropService} from "core-app/modules/grids/grid/drag-and-drop.service";
import {GridResizeService} from "core-app/modules/grids/grid/resize.service";
import {GridMoveService} from "core-app/modules/grids/grid/move.service";
import {GridGap} from "core-app/modules/grids/areas/grid-gap";

@Injectable()
export class GridAddWidgetService {

  constructor(readonly opModalService:OpModalService,
              readonly injector:Injector,
              readonly halResource:HalResourceService,
              readonly layout:GridAreaService,
              readonly drag:GridDragAndDropService,
              readonly move:GridMoveService,
              readonly resize:GridResizeService) {
  }

  public isAddable(area:GridArea) {
    return !this.drag.currentlyDragging &&
      !this.resize.currentlyResizing &&
      (this.layout.mousedOverArea === area || this.layout.isSingleCell || this.layout.isNewlyCreated) &&
      this.isAllowed;
  }

  public widget(area:GridArea) {
    this
      .select(area)
      .then((widgetResource) => {

        if (this.layout.isGap(area)) {
          this.addLine(area as GridGap);
        }

        let newArea = new GridWidgetArea(widgetResource);

        this.setMaxWidth(newArea);

        this.persist(newArea);
      })
      .catch(() => {
        // user didn't select a widget
      });
  }

  private select(area:GridArea) {
    return new Promise<GridWidgetResource>((resolve, reject) => {
      const modal = this.opModalService.show(AddGridWidgetModal, this.injector, { schema: this.layout.schema });
      modal.closingEvent.subscribe((modal:AddGridWidgetModal) => {
        let registered = modal.chosenWidget;

        if (!registered) {
          reject();
          return;
        }

        let source = {
          _type: 'GridWidget',
          identifier: registered.identifier,
          startRow: area.startRow,
          endRow: area.endRow,
          startColumn: area.startColumn,
          endColumn: area.endColumn,
          options: registered.properties || {}
        };

        let resource = this.halResource.createHalResource(source) as GridWidgetResource;

        resource.grid = this.layout.gridResource;

        resolve(resource);
      });
    });
  }

  private addLine(area:GridGap) {
    if (area.isRow) {
      // - 1 to have it added before
      this.layout.addRow(area.startRow - 1, area.startColumn);
    } else if (area.isColumn) {
      // - 1 to have it added before
      this.layout.addColumn(area.startColumn - 1, area.startRow);
    }
  }

  // try to set it to a layout with a height of 1 and as wide as possible
  // but shrink if that is outside the grid or overlaps any other widget
  private setMaxWidth(area:GridWidgetArea) {
    area.endColumn = this.layout.numColumns + 1;

    this.layout.widgetAreas.forEach((existingArea) => {
      if (area.startColumnOverlaps(existingArea)) {
        area.endColumn = existingArea.startColumn;
      }
    });
  }

  private persist(area:GridWidgetArea) {
    area.writeAreaChangeToWidget();
    this.layout.widgetResources.push(area.widget);
    this.layout.writeAreaChangesToWidgets();

    this.layout.buildAreas();
  }

  private get isAllowed() {
    return this.layout.gridResource.updateImmediately;
  }
}
