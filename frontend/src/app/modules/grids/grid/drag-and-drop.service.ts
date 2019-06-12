import {Injectable} from '@angular/core';
import {GridWidgetArea} from "core-app/modules/grids/areas/grid-widget-area";
import {CdkDragEnd, CdkDragEnter, CdkDragDrop} from '@angular/cdk/drag-drop';
import {GridArea} from "core-app/modules/grids/areas/grid-area";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {GridMoveService} from "core-app/modules/grids/grid/move.service";

@Injectable()
export class GridDragAndDropService {
  public draggedArea:GridWidgetArea|null;
  public placeholderArea:GridWidgetArea|null;

  constructor(readonly layout:GridAreaService,
              readonly move:GridMoveService) {

  }

  public entered(event:CdkDragEnter<GridArea>) {
    if (this.draggedArea) {
      let dropArea = event.container.data;
      this.layout.resetAreas(this.draggedArea);
      this.moveAreasOnDragging(dropArea);
    }
  }

  private moveAreasOnDragging(dropArea:GridArea) {
    if (!this.placeholderArea) {
      return;
    }
    let widgetArea = this.draggedArea!;

    // we cannot use the widget's original area as moving it while dragging confuses cdkDrag
    this.placeholderArea.startRow = dropArea.startRow;
    if (this.placeholderArea.startRow + this.placeholderArea.widget.height > this.layout.numRows + 1) {
      this.placeholderArea.endRow = this.layout.numRows + 1;
    } else {
      this.placeholderArea.endRow = dropArea.startRow + this.placeholderArea.widget.height;
    }

    this.placeholderArea.startColumn = dropArea.startColumn;
    if (this.placeholderArea.startColumn + this.placeholderArea.widget.width > this.layout.numColumns + 1) {
      this.placeholderArea.endColumn = this.layout.numColumns + 1;
    } else {
      this.placeholderArea.endColumn = dropArea.startColumn + this.placeholderArea.widget.width;
    }

    this.move.down(this.placeholderArea, widgetArea);
  }

  public get currentlyDragging() {
    return !!this.draggedArea;
  }

  public isDragged(area:GridWidgetArea) {
    return this.currentlyDragging && this.draggedArea!.guid === area.guid;
  }

  public start(area:GridWidgetArea) {
    this.draggedArea = area;
    this.placeholderArea = new GridWidgetArea(area.widget);
  }

  public stop(area:GridWidgetArea, event:CdkDragEnd) {
    if (!this.draggedArea) {
      return;
    }

    this.draggedArea = null;
    this.placeholderArea = null;
  }

  public drop(event:CdkDragDrop<GridArea>) {
    // this.draggedArea is already reset to null at this point
    let dropArea = event.container.data;
    let draggedArea = event.previousContainer.data as GridWidgetArea;

    // Set the draggedArea's startRow/startColumn properties
    // to the drop zone ones.
    // The dragged Area should keep it's height and width normally but will
    // shrink if the area would otherwise end outside the grid.
    draggedArea.startRow = dropArea.startRow;
    if (dropArea.startRow + draggedArea.widget.height > this.layout.numRows + 1) {
      draggedArea.endRow = this.layout.numRows + 1;
    } else {
      draggedArea.endRow = dropArea.startRow + draggedArea.widget.height;
    }

    draggedArea.startColumn = dropArea.startColumn;
    if (dropArea.startColumn + draggedArea.widget.width > this.layout.numColumns + 1) {
      draggedArea.endColumn = this.layout.numColumns + 1;
    } else {
      draggedArea.endColumn = dropArea.startColumn + draggedArea.widget.width;
    }

    this.layout.writeAreaChangesToWidgets();
    this.layout.buildAreas();
  }

}
