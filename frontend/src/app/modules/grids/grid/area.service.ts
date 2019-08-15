import {Injectable} from '@angular/core';
import {GridWidgetArea} from "app/modules/grids/areas/grid-widget-area";
import {GridArea} from "core-app/modules/grids/areas/grid-area";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {WidgetChangeset} from "core-app/modules/grids/widgets/widget-changeset";

@Injectable()
export class GridAreaService {

  private resource:GridResource;
  public schema:SchemaResource;

  public numColumns:number = 0;
  public numRows:number = 0;
  public gridAreas:GridArea[];
  public widgetAreas:GridWidgetArea[];
  public gridAreaIds:string[];
  public mousedOverArea:GridArea|null;

  constructor (private gridDm:GridDmService) { }

  public set gridResource(value:GridResource) {
    this.resource = value;
    this.fetchSchema();

    this.numRows = this.resource.rowCount;
    this.numColumns = this.resource.columnCount;

    this.buildAreas(false);
  }

  public get gridResource() {
    return this.resource;
  }

  public setMousedOverArea(area:GridArea) {
    this.mousedOverArea = area;
  }

  public buildAreas(save = true) {
    this.gridAreas = this.buildGridAreas();
    this.gridAreaIds = this.buildGridAreaIds();
    this.widgetAreas = this.buildGridWidgetAreas();

    this.resource.rowCount = this.numRows;
    this.resource.columnCount = this.numColumns;

    if (save) {
      this.saveGrid(this.resource, this.schema);
    }
  }

  public saveWidgetChangeset(changeset:WidgetChangeset) {
    let payload = this.gridDm.extractPayload(this.resource, this.schema);

    let payloadWidget = payload.widgets.find((w:any) => w.id === changeset.resource.id);
    Object.assign(payloadWidget, changeset.changes);

    // Adding the id so that the url can be deduced
    payload['id'] = this.resource.id;

    this.saveGrid(payload);
  }

  private saveGrid(resource:GridWidgetResource|any, schema?:SchemaResource) {
    this
      .gridDm
      .update(resource, schema)
      .then(updatedGrid => {
        this.assignAreasWidget(updatedGrid);
      });
  }

  private assignAreasWidget(newGrid:GridResource) {
    this.resource.widgets = newGrid.widgets;

    let takenIds = this.widgetAreas.map(a => a.widget.id);
    this.widgetAreas.forEach(area => {
      let newWidget:GridWidgetResource;

      // identify the right resource for the area. Typically that means fetching them by id.
      // But new areas have unpersisted resources at first. Unpersisted resources have no id.
      // In those cases, we find the one resource which is not claimed by any other area.
      if (area.widget.id) {
        newWidget = newGrid.widgets.find(widget => widget.id === area.widget.id)!;
      } else {
        newWidget = newGrid.widgets.find(widget => !takenIds.includes(widget.id) && widget.identifier === area.widget.identifier && widget.startRow === area.widget.startRow && widget.startColumn === area.widget.startColumn)!;
      }

      area.widget = newWidget!;
    });
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
    this.resource.widgets = this.widgetResources.filter((widget) => {
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
    this.resource.widgets = this.widgetResources.filter((widget) => {
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

  private buildGridAreaIds() {
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

  public removeWidget(removedWidget:GridWidgetResource) {
    this.resource.widgets = this.widgetResources.filter((widget) => widget.id !== removedWidget.id );
  }

  public get widgetResources() {
    return (this.resource && this.resource.widgets) || [];
  }
}
