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
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {GridMoveService} from "core-app/modules/grids/grid/move.service";

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
      this.layout.mousedOverArea === area &&
      this.isAllowed;
  }

  public widget(area:GridArea, schema:SchemaResource) {
    this
      .select(area, schema)
      .then((widgetResource) => {
        // try to set it to a 2 x 3 layout
        // but shrink if that is outside the grid or
        // overlaps any other widget

        // rowGap
        if (this.layout.isGap(area)) {
          widgetResource.startRow = Math.floor(widgetResource.startRow / 2) + 1;
          widgetResource.endRow = Math.floor(widgetResource.endRow / 2) + 1;
          widgetResource.startColumn = Math.floor(widgetResource.startColumn / 2);
          widgetResource.endColumn = Math.floor(widgetResource.endColumn / 2) + 1;
        } else {
          widgetResource.startRow = Math.floor(widgetResource.startRow / 2);
          widgetResource.endRow = Math.floor(widgetResource.endRow / 2) + 1;
          widgetResource.startColumn = Math.floor(widgetResource.startColumn / 2);
          widgetResource.endColumn = Math.floor(widgetResource.endColumn / 2) + 1;
        }

        let newArea = new GridWidgetArea(widgetResource);

        // Added at last row gap
        if (this.layout.isGap(area) && this.layout.numRows * 2 + 1 === area.startRow) {
          this.layout.addRow(this.layout.numRows, false);
        // Added at non last row gap
        } else if (this.layout.isGap(area)) {
          this.move.down(newArea, newArea);
        }

        //newArea.endColumn = newArea.endColumn + 1;
        //newArea.endRow = newArea.endRow + 2;

        //let maxRow:number = this.layout.numRows + 1;
        //let maxColumn:number = this.layout.numColumns + 1;

        //this.layout.widgetAreas.forEach((existingArea) => {
        //  if (newArea.startColumnOverlaps(existingArea) &&
        //    maxColumn > existingArea.startColumn) {
        //    maxColumn = existingArea.startColumn;
        //  }
        //});

        //if (maxColumn < newArea.endColumn) {
        //  newArea.endColumn = maxColumn;
        //}

        //this.layout.widgetAreas.forEach((existingArea) => {
        //  if (newArea.overlaps(existingArea) &&
        //    maxRow > existingArea.startRow) {
        //    maxRow = existingArea.startRow;
        //  }
        //});

        //if (maxRow < newArea.endRow) {
        //  newArea.endRow = maxRow;
        //}

        //newArea.writeAreaChangeToWidget();

        //if (this.layout.isGap(area)) {
        //} else {
        //
        //}

        this.layout.widgetResources.push(newArea.widget);
        this.layout.writeAreaChangesToWidgets();

        this.layout.buildAreas();
      })
      .catch(() => {
        // user didn't select a widget
      });
  }

  private select(area:GridArea, schema:SchemaResource) {
    return new Promise<GridWidgetResource>((resolve, reject) => {
      const modal = this.opModalService.show(AddGridWidgetModal, this.injector, { schema: schema });
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

  private get isAllowed() {
    return this.layout.gridResource.updateImmediately;
  }
}
