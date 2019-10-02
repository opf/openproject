import {Injectable} from '@angular/core';
import {GridWidgetArea} from "core-app/modules/grids/areas/grid-widget-area";
import {GridArea} from "core-app/modules/grids/areas/grid-area";
import {ResizeDelta} from "core-app/modules/common/resizer/resizer.component";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {GridMoveService} from "core-app/modules/grids/grid/move.service";
import {GridDragAndDropService} from "core-app/modules/grids/grid/drag-and-drop.service";

@Injectable()
export class GridResizeService {
  public placeholderArea:GridWidgetArea|null;
  private resizedArea:GridWidgetArea|null;
  private targetIds:string[];

  constructor(readonly layout:GridAreaService,
              readonly move:GridMoveService,
              readonly drag:GridDragAndDropService) { }

  public end(area:GridWidgetArea, deltas:ResizeDelta) {
    if (!this.placeholderArea ||
      !this.resizedArea) {
      return;
    }

    this.resizedArea.endRow = this.placeholderArea.endRow;
    this.resizedArea.endColumn = this.placeholderArea.endColumn;

    this.layout.writeAreaChangesToWidgets();
    this.layout.cleanupUnusedAreas();

    this.resizedArea = null;
    this.placeholderArea = null;

    this.layout.rebuildAndPersist();
  }

  public start(resizedArea:GridWidgetArea) {
    this.placeholderArea = new GridWidgetArea(resizedArea.widget);
    this.resizedArea = resizedArea;

    let resizeTargets = this.layout.gridAreas.filter((area) => {
      // All areas on the same row which are after the current column are valid targets.
      let sameRow = area.startRow === this.placeholderArea!.startRow &&
                     area.endRow === this.placeholderArea!.endRow &&
                     area.startColumn >= this.placeholderArea!.startColumn;

      // Areas that are on higher (number, they are printed below) rows
      // are allowed as long as there is guaranteed to always be one widget
      // before or after the resized to area.
      let higherRow = area.startRow > this.placeholderArea!.startRow &&
                      area.startColumn >= this.placeholderArea!.startColumn &&
                      this.layout.widgetAreas.some((fixedArea) => {
                        return fixedArea.startRow === area.startRow &&
                        // before
                        (fixedArea.endColumn <= this.placeholderArea!.startColumn ||
                          // after
                          fixedArea.startColumn >= area.endColumn);
                      });
       return sameRow || higherRow;
    });

    this.targetIds = resizeTargets
                     .map(area => area.guid);
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
