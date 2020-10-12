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

  public reset() {
    this.startRow = this.widget.startRow;
    this.endRow = this.widget.endRow;
    this.startColumn = this.widget.startColumn;
    this.endColumn = this.widget.endColumn;
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

  public get unchangedSize() {
    return this.startColumn === this.widget.startColumn &&
           this.endColumn === this.widget.endColumn &&
           this.startRow === this.widget.startRow &&
           this.endRow === this.widget.endRow;
  }

  public writeAreaChangeToWidget() {
    this.widget.startRow = this.startRow;
    this.widget.endRow = this.endRow;
    this.widget.startColumn = this.startColumn;
    this.widget.endColumn = this.endColumn;
  }

  public copyDimensionsTo(sink:GridWidgetArea) {
    sink.startRow = this.startRow;
    sink.startColumn = this.startColumn;
    sink.endRow = this.endRow;
    sink.endColumn = this.endColumn;
  }
}
