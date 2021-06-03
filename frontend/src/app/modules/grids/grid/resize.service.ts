import { Injectable } from '@angular/core';
import { GridWidgetArea } from "core-app/modules/grids/areas/grid-widget-area";
import { GridArea } from "core-app/modules/grids/areas/grid-area";
import { ResizeDelta } from "core-app/modules/common/resizer/resizer.component";
import { GridAreaService } from "core-app/modules/grids/grid/area.service";
import { GridMoveService } from "core-app/modules/grids/grid/move.service";
import { GridDragAndDropService } from "core-app/modules/grids/grid/drag-and-drop.service";

@Injectable()
export class GridResizeService {
  private resizedArea:GridWidgetArea|null;
  private targetIds:string[];

  constructor(readonly layout:GridAreaService,
              readonly move:GridMoveService,
              readonly drag:GridDragAndDropService) { }

  public end(area:GridWidgetArea) {
    if (!this.resizedArea) {
      return;
    }

    this.resizedArea = null;

    // user aborted resizing
    if (area.unchangedSize) {
      return;
    }

    this.layout.writeAreaChangesToWidgets();
    this.layout.cleanupUnusedAreas();

    this.layout.rebuildAndPersist();
  }

  public abort() {
    if (this.resizedArea) {
      this.layout.resetAreas();
      this.resizedArea = null;
    }
  }

  public start(resizedArea:GridWidgetArea) {
    this.resizedArea = resizedArea;

    const resizeTargets = this.layout.gridAreas.filter((area) => {
      // All areas on the same row which are after the current column are valid targets.
      const sameRow = area.startRow === this.resizedArea!.startRow &&
                     area.startColumn >= this.resizedArea!.startColumn;

      // Areas that are on higher (number, they are printed below) rows
      // are allowed as long as there is guaranteed to always be one widget
      // before or after the resized to area.
      const higherRow = area.startRow > this.resizedArea!.startRow &&
                      area.startColumn >= this.resizedArea!.startColumn &&
                      this.layout.widgetAreas.some((fixedArea) => {
                        return fixedArea.startRow === area.startRow &&
                        // before
                        (fixedArea.endColumn <= this.resizedArea!.startColumn ||
                          // after
                          fixedArea.startColumn >= area.endColumn);
                      });
      return sameRow || higherRow;
    });

    this.targetIds = resizeTargets
      .map(area => area.guid);
  }

  public moving(deltas:ResizeDelta) {
    if (!this.resizedArea ||
      !this.layout.mousedOverArea ||
      !this.targetIds.includes(this.layout.mousedOverArea.guid)) {
      return;
    }

    this.layout.resetAreas();

    this.resizedArea.endRow = this.layout.mousedOverArea.endRow;
    this.resizedArea.endColumn = this.layout.mousedOverArea.endColumn;

    this.move.down(this.resizedArea, this.resizedArea);
  }

  public isTarget(area:GridArea) {
    const areaId = area.guid;

    return this.resizedArea && this.targetIds.includes(areaId);
  }

  public isResized(area:GridWidgetArea) {
    return this.resizedArea && this.resizedArea.guid === area.guid;
  }

  public isPassive(area:GridWidgetArea) {
    return this.currentlyResizing && !this.isResized(area);
  }

  public get currentlyResizing() {
    return !!this.resizedArea;
  }

  public get isResizable() {
    return !this.drag.currentlyDragging && this.isAllowed;
  }

  private get isAllowed() {
    return this.layout.gridResource.updateImmediately;
  }
}
