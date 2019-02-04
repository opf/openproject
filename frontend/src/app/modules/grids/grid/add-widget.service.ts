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

@Injectable()
export class GridAddWidgetService {

  constructor(readonly opModalService:OpModalService,
              readonly injector:Injector,
              readonly halResource:HalResourceService,
              readonly layout:GridAreaService,
              readonly drag:GridDragAndDropService,
              readonly resize:GridResizeService) {
  }

  public isAddable(area:GridArea) {
    return !this.drag.currentlyDragging &&
      !this.resize.currentlyResizing &&
      this.layout.mousedOverArea === area &&
      this.layout.widgetAreaIds.includes(area.guid);
  }

  public widget(area:GridArea) {
    this
      .select(area)
      .then((widgetResource) => {
        // try to set it to a 2 x 3 layout
        // but shrink if that is outside the grid or
        // overlaps any other widget
        let newArea = new GridWidgetArea(widgetResource);

        newArea.endColumn = newArea.endColumn + 1;
        newArea.endRow = newArea.endRow + 2;

        let maxRow:number = this.layout.numRows + 1;
        let maxColumn:number = this.layout.numColumns + 1;

        this.layout.widgetAreas.forEach((existingArea) => {
          if (newArea.startColumnOverlaps(existingArea) &&
            maxColumn > existingArea.startColumn) {
            maxColumn = existingArea.startColumn;
          }
        });

        if (maxColumn < newArea.endColumn) {
          newArea.endColumn = maxColumn;
        }

        this.layout.widgetAreas.forEach((existingArea) => {
          if (newArea.overlaps(existingArea) &&
            maxRow > existingArea.startRow) {
            maxRow = existingArea.startRow;
          }
        });

        if (maxRow < newArea.endRow) {
          newArea.endRow = maxRow;
        }

        newArea.writeAreaChangeToWidget();

        this.layout.widgetResources.push(newArea.widget);

        this.layout.buildAreas();
      })
      .catch(() => {
        // user didn't select a widget
      });
  }

  private select(area:GridArea) {
    return new Promise<GridWidgetResource>((resolve, reject) => {
      const modal = this.opModalService.show(AddGridWidgetModal, { });
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
          endColumn: area.endColumn
        };

        let resource = this.halResource.createHalResource(source) as GridWidgetResource;

        resolve(resource);
      });
    });
  }
}
