import {Injectable} from '@angular/core';
import {GridWidgetArea} from "core-app/modules/grids/areas/grid-widget-area";
import {GridArea} from "core-app/modules/grids/areas/grid-area";
import {ResizeDelta} from "core-app/modules/common/resizer/resizer.component";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {GridMoveService} from "core-app/modules/grids/grid/move.service";

@Injectable()
export class GridResizeService {
  public placeholderArea:GridWidgetArea|null;
  private resizedArea:GridWidgetArea|null;
  private targetIds:string[];

  constructor(readonly layout:GridAreaService,
              readonly move:GridMoveService) { }

  public end(area:GridWidgetArea, deltas:ResizeDelta) {
    if (!this.placeholderArea ||
      !this.resizedArea) {
      return;
    }

    this.resizedArea.endRow = this.placeholderArea.endRow;
    this.resizedArea.endColumn = this.placeholderArea.endColumn;

    this.layout.writeAreaChangesToWidgets();
    this.layout.buildAreas();

    this.resizedArea = null;
    this.placeholderArea = null;
  }

  public start(resizedArea:GridWidgetArea) {
    this.placeholderArea = new GridWidgetArea(resizedArea.widget);
    this.resizedArea = resizedArea;

    let resizeTargets = this.layout.gridAreas.filter((area) => {
      return area.startRow >= this.placeholderArea!.startRow &&
        area.startColumn >= this.placeholderArea!.startColumn;
    });

    this.targetIds = resizeTargets.map((area) => {
      return area.guid;
    });
  }

  public moving(deltas:ResizeDelta) {
    if (!this.placeholderArea ||
      !this.resizedArea ||
      !this.layout.mousedOverArea ||
      !this.targetIds.includes(this.layout.mousedOverArea.guid)) {
      return;
    }

    this.layout.resetAreas();

    this.placeholderArea.endRow = this.layout.mousedOverArea.endRow;
    this.placeholderArea.endColumn = this.layout.mousedOverArea.endColumn;

    this.move.down(this.placeholderArea, this.resizedArea);
  }

  public isTarget(area:GridArea) {
    let areaId = area.guid;

    return this.placeholderArea && this.targetIds.includes(areaId);
  }

  public get currentlyResizing() {
    return this.placeholderArea;
  }
}
