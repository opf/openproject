import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {GridArea} from "app/modules/grids/areas/grid-area";

export class GridWidgetArea extends GridArea {
  public widget:GridWidgetResource;

  constructor(widget:GridWidgetResource) {
    super(widget.startRow,
      widget.endRow,
      widget.startColumn,
      widget.endColumn);

    this.widget = widget;
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
    this.widget.startRow = this.startRow;
    this.widget.endRow = this.endRow;
    this.widget.startColumn = this.startColumn;
    this.widget.endColumn = this.endColumn;
  }
}
