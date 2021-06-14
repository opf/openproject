import { Injectable, Injector } from "@angular/core";
import { OpModalService } from "core-app/modules/modal/modal.service";
import { AddGridWidgetModal } from "app/modules/grids/widgets/add/add.modal";
import { GridWidgetResource } from "app/modules/hal/resources/grid-widget-resource";
import { GridArea } from "app/modules/grids/areas/grid-area";
import { HalResourceService } from "app/modules/hal/services/hal-resource.service";
import { GridWidgetArea } from "core-app/modules/grids/areas/grid-widget-area";
import { GridAreaService } from "core-app/modules/grids/grid/area.service";
import { GridDragAndDropService } from "core-app/modules/grids/grid/drag-and-drop.service";
import { GridResizeService } from "core-app/modules/grids/grid/resize.service";
import { GridMoveService } from "core-app/modules/grids/grid/move.service";
import { GridGap } from "core-app/modules/grids/areas/grid-gap";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";

@Injectable()
export class GridAddWidgetService {

  text = { add: this.i18n.t('js.grid.add_widget') };

  constructor(readonly opModalService:OpModalService,
              readonly injector:Injector,
              readonly halResource:HalResourceService,
              readonly layout:GridAreaService,
              readonly drag:GridDragAndDropService,
              readonly move:GridMoveService,
              readonly resize:GridResizeService,
              readonly i18n:I18nService) {
  }

  public isAddable(area:GridArea) {
    return !this.drag.currentlyDragging &&
      !this.resize.currentlyResizing &&
      (this.layout.mousedOverArea === area || this.layout.isSingleCell || this.layout.inHelpMode) &&
      this.isAllowed;
  }

  public widget(area:GridArea) {
    this
      .select(area)
      .then((widgetResource) => {

        if (this.layout.isGap(area)) {
          this.addLine(area as GridGap);
        }

        const newArea = new GridWidgetArea(widgetResource);

        this.setMaxWidth(newArea);

        this.persist(newArea);
      })
      .catch(() => {
        // user didn't select a widget
      });
  }

  public get addText() {
    return this.text.add;
  }

  private select(area:GridArea) {
    return new Promise<GridWidgetResource>((resolve, reject) => {
      const modal = this.opModalService.show(AddGridWidgetModal, this.injector, { schema: this.layout.schema });
      modal.closingEvent.subscribe((modal:AddGridWidgetModal) => {
        const registered = modal.chosenWidget;

        if (!registered) {
          reject();
          return;
        }

        const source = {
          _type: 'GridWidget',
          identifier: registered.identifier,
          startRow: area.startRow,
          endRow: area.endRow,
          startColumn: area.startColumn,
          endColumn: area.endColumn,
          options: registered.properties || {}
        };

        const resource = this.halResource.createHalResource(source) as GridWidgetResource;

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
    this.layout.widgetAreas.push(area);
    this.layout.widgetResources.push(area.widget);
    this.layout.rebuildAndPersist();
  }

  public get isAllowed() {
    return this.layout.gridResource && this.layout.gridResource.updateImmediately;
  }
}
