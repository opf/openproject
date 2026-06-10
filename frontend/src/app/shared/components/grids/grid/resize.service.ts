import { Injectable, inject } from '@angular/core';
import { GridWidgetArea } from 'core-app/shared/components/grids/areas/grid-widget-area';
import { GridArea } from 'core-app/shared/components/grids/areas/grid-area';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridMoveService } from 'core-app/shared/components/grids/grid/move.service';
import { GridDragAndDropService } from 'core-app/shared/components/grids/grid/drag-and-drop.service';

@Injectable()
export class GridResizeService {
  readonly layout = inject(GridAreaService);
  readonly move = inject(GridMoveService);
  readonly drag = inject(GridDragAndDropService);

  private resizedArea:GridWidgetArea|null;

  private targetIds:string[];

  public end(area:GridWidgetArea):Promise<GridResource>|undefined {
    if (!this.resizedArea) {
      return undefined;
    }

    this.resizedArea = null;

    // user aborted resizing
    if (area.unchangedSize) {
      return undefined;
    }

    this.layout.writeAreaChangesToWidgets();
    this.layout.cleanupUnusedAreas();

    return this.layout.rebuildAndPersist();
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
      const sameRow = area.startRow === this.resizedArea!.startRow
                     && area.startColumn >= this.resizedArea!.startColumn;

      // Areas that are on higher (number, they are printed below) rows
      // are allowed as long as there is guaranteed to always be one widget
      // before or after the resized to area.
      const higherRow = area.startRow > this.resizedArea!.startRow
                      && area.startColumn >= this.resizedArea!.startColumn
                      && this.layout.widgetAreas.some((fixedArea) => fixedArea.startRow === area.startRow
                        // before
                        && (fixedArea.endColumn <= this.resizedArea!.startColumn
                          // after
                          || fixedArea.startColumn >= area.endColumn));
      return sameRow || higherRow;
    });

    this.targetIds = resizeTargets
      .map((area) => area.guid);
  }

  public moving() {
    if (!this.resizedArea
      || !this.layout.mousedOverArea
      || !this.targetIds.includes(this.layout.mousedOverArea.guid)) {
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
    return this.resizedArea?.guid === area.guid;
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
