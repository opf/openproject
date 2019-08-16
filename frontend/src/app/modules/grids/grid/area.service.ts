import {Injectable} from '@angular/core';
import {GridWidgetArea} from "app/modules/grids/areas/grid-widget-area";
import {GridArea} from "core-app/modules/grids/areas/grid-area";
import {GridGap} from "core-app/modules/grids/areas/grid-gap";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {WidgetChangeset} from "core-app/modules/grids/widgets/widget-changeset";
import * as moment from 'moment';

@Injectable()
export class GridAreaService {

  private resource:GridResource;
  public schema:SchemaResource;

  public numColumns:number = 0;
  public numRows:number = 0;
  public gridAreas:GridArea[];
  public gridGaps:GridArea[];
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

  public cleanupUnusedAreas(save = true) {
    let unusedRows = Array.from(Array(this.numRows + 1).keys()).slice(1);

    this.widgetResources.forEach(widget => {
      unusedRows = unusedRows.filter(item => item !== widget.startRow);
    });

    unusedRows.forEach(number => {
      if (this.numRows > 1) {
        this.removeRow(number, save);
      }
    });

    let unusedColumns = Array.from(Array(this.numColumns + 1).keys()).slice(1);

    this.widgetResources.forEach(widget => {
      unusedColumns = unusedColumns.filter(item => item !== widget.startColumn);
    });

    unusedColumns.forEach(number => {
      if (this.numColumns > 1) {
        this.removeColumn(number, save);
      }
    });
  }

  public buildAreas(save = true) {
    this.gridAreas = this.buildGridAreas();
    this.gridGaps = this.buildGridGaps();
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

  public isGap(area:GridArea) {
    return area instanceof GridGap;
  }

  public get isSingleCell() {
    return this.numRows === 1 && this.numColumns === 1 && this.widgetResources.length === 0;
  }

  public get isNewlyCreated() {
    return moment(moment.utc()).diff(moment(this.resource.createdAt), 'seconds') < 20;
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

  private buildGridGaps() {
    let cells:GridArea[] = [];

    // special case where we want no gaps
    if (this.isSingleCell) {
      return cells;
    }

    for (let row = 1; row <= this.numRows + 1; row++) {
      cells.push(...this.buildGridGapRow(row));
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

  private buildGridGapRow(row:number) {
    let cells:GridGap[] = [];

    for (let column = 1; column <= this.numColumns; column++) {
      cells.push(new GridGap(row,
                                  row + 1,
                             column,
                                  column + 1,
                                  'row'));
    }

    if (row <= this.numRows) {
      for (let column = 1; column <= this.numColumns + 1; column++) {
        cells.push(new GridGap(row,
          row + 1,
          column,
          column + 1,
          'column'));
      }
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

  public addColumn(column:number, excludeRow:number) {
    this.numColumns++;

    let movedWidgets:GridWidgetArea[] = [];

    for (let row = 1; row <= this.numRows; row++) {
      if (row === excludeRow) {
        continue;
      }

      let widget = this
                   .rowWidgets(row)
                   .sort((a, b) => a.startColumn - b.startColumn)
                   .find(widget => !(widget.startRow < excludeRow && widget.endRow > excludeRow) &&
                     (widget.startColumn === column + 1 ||
                      widget.endColumn === column + 1 ||
                      widget.startColumn <= column && widget.endColumn > column));

      if (widget) {
        movedWidgets.push(widget);
        widget.endColumn++;
      }
    }

    this.moveSubsequentRowWidgets(this.widgetAreas.filter(widget => !movedWidgets.includes(widget)),
                                  column);
  }

  public addRow(row:number, excludeColumn:number) {
    this.numRows++;

    let movedWidgets:GridWidgetArea[] = [];

    for (let column = 1; column <= this.numColumns; column++) {
      if (column === excludeColumn) {
        continue;
      }

      let widget = this
                   .columnWidgets(column)
                   .sort((a, b) => a.startRow - b.startRow)
                   .find(widget => !(widget.startColumn < excludeColumn && widget.endColumn > excludeColumn) &&
                     (widget.startRow === row + 1 ||
                       widget.endRow === row + 1 ||
                       widget.startRow <= row && widget.endRow > row));

      if (widget) {
        movedWidgets.push(widget);
        widget.endRow++;
      }
    }

    this.moveSubsequentColumnWidgets(this.widgetAreas.filter(widget => !movedWidgets.includes(widget)),
                                     row);
  }

  public removeColumn(column:number, save = true) {
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

    this.buildAreas(save);
  }

  public removeRow(row:number, save = true) {
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

    this.buildAreas(save);
  }

  public resetAreas(ignoredArea:GridWidgetArea|null = null) {
    this.widgetAreas.filter((area) => {
      return !ignoredArea || area.guid !== ignoredArea.guid;
    }).forEach(area => area.reset());

    this.numRows = this.resource.rowCount;
    this.numColumns = this.resource.columnCount;
  }

  public get isEditable() {
    return this.gridResource.updateImmediately !== undefined;
  }

  private buildGridAreaIds() {
    return this
      .gridAreas
      .filter(area => !this.isGap(area))
      .map((area) => area.guid);
  }

  private fetchSchema() {
    this.gridDm.updateForm(this.resource)
      .then((form) => {
        this.schema = form.schema;
      });
  }

  public removeWidget(removedWidget:GridWidgetResource) {
    this.resource.widgets = this.widgetResources.filter((widget) => widget.id !== removedWidget.id );
    this.cleanupUnusedAreas(true);
  }

  public get widgetResources() {
    return (this.resource && this.resource.widgets) || [];
  }

  private rowWidgets(row:number) {
    return this.widgetAreas.filter(widget => widget.startRow === row);
  }

  private moveSubsequentRowWidgets(rowWidgets:GridWidgetArea[], column:number) {
    rowWidgets.forEach(subsequentWidget => {
      if (subsequentWidget.startColumn > column) {
        subsequentWidget.startColumn++;
        subsequentWidget.endColumn++;
      }
    });
  }

  private columnWidgets(column:number) {
    return this.widgetAreas.filter(widget => widget.startColumn === column);
  }

  private moveSubsequentColumnWidgets(columnWidgets:GridWidgetArea[], row:number) {
    columnWidgets.forEach(subsequentWidget => {
      if (subsequentWidget.startRow > row) {
        subsequentWidget.startRow++;
        subsequentWidget.endRow++;
      }
    });
  }
}
