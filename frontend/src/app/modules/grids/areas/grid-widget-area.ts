import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {GridArea} from "app/modules/grids/areas/grid-area";

export class GridWidgetArea extends GridArea {
  public widget:GridWidgetResource;

  constructor(widget:GridWidgetResource) {
    super(widget.startRow * 2,
      widget.endRow * 2 - 1,
      widget.startColumn * 2,
      widget.endColumn * 2 - 1);

    this.widget = widget;
  }

  public reset() {
    this.startRow = this.widget.startRow * 2;
    this.endRow = this.widget.endRow * 2 - 1;
    this.startColumn = this.widget.startColumn * 2;
    this.endColumn = this.widget.endColumn * 2 - 1;
  }

  public moveRight() {
    this.startColumn++;
    this.endColumn++;
  }

  public moveLeft() {
    this.startColumn--;
    this.endColumn--;
  }

  public growColumn() {
    this.endColumn++;
  }

  public overlaps(otherArea:GridWidgetArea) {
    return this.rowOverlaps(otherArea) &&
           this.columnOverlaps(otherArea);
  }

  public rowOverlaps(otherArea:GridWidgetArea) {
    return this.startRow < otherArea.endRow &&
           this.endRow >= otherArea.endRow ||
           this.startRow <= otherArea.startRow &&
           this.endRow > otherArea.startRow ||
           this.startRow > otherArea.startRow &&
           this.endRow < otherArea.endRow;
  }

  public columnOverlaps(otherArea:GridWidgetArea) {
    return this.startColumn < otherArea.endColumn &&
           this.endColumn >= otherArea.endColumn ||
           this.startColumn <= otherArea.startColumn &&
           this.endColumn > otherArea.startColumn ||
           this.startColumn > otherArea.startColumn &&
           this.endColumn < otherArea.endColumn;
  }

  public startColumnOverlaps(otherArea:GridWidgetArea) {
    return this.startColumn < otherArea.startColumn &&
           this.endColumn > otherArea.startColumn &&
           this.rowOverlaps(otherArea);
  }

  public writeAreaChangeToWidget() {
    this.widget.startRow = this.startRow / 2;
    this.widget.endRow = (this.endRow + 1) / 2;
    this.widget.startColumn = this.startColumn / 2;
    this.widget.endColumn = (this.endColumn + 1) / 2;
  }
}
