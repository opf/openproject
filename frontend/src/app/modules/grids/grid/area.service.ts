import {Injectable} from '@angular/core';
import {GridWidgetArea} from "app/modules/grids/areas/grid-widget-area";
import {GridArea} from "core-app/modules/grids/areas/grid-area";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";


@Injectable()
export class GridAreaService {

  private resource:GridResource;
  private schema:SchemaResource;

  public numColumns:number = 0;
  public numRows:number = 0;
  public gridAreas:GridArea[];
  public widgetAreas:GridWidgetArea[];
  public widgetAreaIds:string[];
  public widgetResources:GridWidgetResource[] = [];
  public mousedOverArea:GridArea|null;

  constructor (private gridDm:GridDmService) {
  }

  public set gridResource(value:GridResource) {
    this.resource = value;

    this.fetchSchema();

    this.numRows = this.resource.rowCount;
    this.numColumns = this.resource.columnCount;

    this.widgetResources = this.resource.widgets;

    this.buildAreas(false);
  }

  public setMousedOverArea(area:GridArea) {
    this.mousedOverArea = area;
  }

  public buildAreas(save = true) {
    this.gridAreas = this.buildGridAreas();
    this.widgetAreaIds = this.buildWidgetAreaIds();
    this.widgetAreas = this.buildGridWidgetAreas();

    this.resource.widgets = this.widgetResources;
    this.resource.rowCount = this.numRows;
    this.resource.columnCount = this.numColumns;

    if (save) {
      this.gridDm.update(this.resource, this.schema);
    }
  }

  private buildGridAreas() {
    let cells:GridArea[] = [];

    for (let row = 1; row <= this.numRows; row++) {
      cells.push(...this.buildGridAreasRow(row));
    }

    return cells;
  }

  private buildGridAreasColumn(column:number) {
    let cells:GridArea[] = [];

    for (let row = 1; row <= this.numRows; row++) {
      let cell = new GridArea(row,
        row + 1,
        column,
        column + 1);

      cells.push(cell);
    }

    return cells;
  }

  private buildGridAreasRow(row:number) {
    let cells:GridArea[] = [];

    for (let column = 1; column <= this.numColumns; column++) {
      let cell = new GridArea(row,
        row + 1,
        column,
        column + 1);

      cells.push(cell);
    }

    return cells;
  }

  private buildGridWidgetAreas() {
    return this.widgetResources.map((widget) => {
      return new GridWidgetArea(widget);
    });
  }

  // persist all changes to the areas caused by dragging/resizing
  // to the widget
  public writeAreaChangesToWidgets() {
    this.widgetAreas.forEach((area) => {
      area.writeAreaChangeToWidget();
    });
  }

  public addColumn(column:number) {
    this.numColumns++;

    this.widgetResources.filter((widget) => {
      return widget.startColumn > column;
    }).forEach((widget) => {
      widget.startColumn++;
      widget.endColumn++;
    });

    this.buildAreas();
  }

  public addRow(row:number) {
    this.numRows++;

    this.widgetResources.filter((widget) => {
      return widget.startRow > row;
    }).forEach((widget) => {
      widget.startRow++;
      widget.endRow++;
    });

    this.buildAreas();
  }

  public removeColumn(column:number) {
    this.numColumns--;

    // remove widgets that only span the removed column
    this.widgetResources = this.widgetResources.filter((widget) => {
      return !(widget.startColumn === column && widget.endColumn === column + 1);
    });

    //shrink widgets that span more than the removed column
    this.widgetResources.forEach((widget) => {
      if (widget.startColumn <= column && widget.endColumn >= column + 1) {
        //shrink widgets that span more than the removed column
        widget.endColumn--;
      }
    });

    // move all widgets that are after the removed column
    // so that they appear to keep their place.
    this.widgetResources.filter((widget) => {
      return widget.startColumn > column;
    }).forEach((widget) => {
      widget.startColumn--;
      widget.endColumn--;
    });

    this.buildAreas();
  }

  public removeRow(row:number) {
    this.numRows--;

    // remove widgets that only span the removed row
    this.widgetResources = this.widgetResources.filter((widget) => {
      return !(widget.startRow === row && widget.endRow === row + 1);
    });

    //shrink widgets that span more than the removed row
    this.widgetResources.forEach((widget) => {
      if (widget.startRow <= row && widget.endRow >= row + 1) {
        //shrink widgets that span more than the removed row
        widget.endRow--;
      }
    });

    // move all widgets that are after the removed row
    // so that they appear to keep their place.
    this.widgetResources.filter((widget) => {
      return widget.startRow > row;
    }).forEach((widget) => {
      widget.startRow--;
      widget.endRow--;
    });

    this.buildAreas();
  }

  public resetAreas(ignoredArea:GridWidgetArea|null = null) {
    this.widgetAreas.filter((area) => {
      return !ignoredArea || area.guid !== ignoredArea.guid;
    }).forEach((area) => {
      area.startRow = area.widget.startRow;
      area.endRow = area.widget.endRow;
      area.startColumn = area.widget.startColumn;
      area.endColumn = area.widget.endColumn;
    });

    this.numRows = this.resource.rowCount;
    this.numColumns = this.resource.columnCount;
  }

  private buildWidgetAreaIds() {
    return this.gridAreas.map((area) => {
      return area.guid;
    });
  }

  private fetchSchema() {
    this.gridDm.updateForm(this.resource)
      .then((form) => {
        this.schema = form.schema;
      });
  }
}
