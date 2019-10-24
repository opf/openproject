import {Injectable} from '@angular/core';
import {GridWidgetArea} from "app/modules/grids/areas/grid-widget-area";
import {GridArea} from "core-app/modules/grids/areas/grid-area";
import {GridGap} from "core-app/modules/grids/areas/grid-gap";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {WidgetChangeset} from "core-app/modules/grids/widgets/widget-changeset";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import { BehaviorSubject } from 'rxjs';

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
  public mousedOverArea:GridArea|null = null;
  public $mousedOverArea = new BehaviorSubject(this.mousedOverArea);
  public helpMode = false;

  constructor (private gridDm:GridDmService,
               private notification:NotificationsService,
               private i18n:I18nService) { }

  public set gridResource(value:GridResource) {
    this.resource = value;
    this.fetchSchema();

    this.numRows = this.resource.rowCount;
    this.numColumns = this.resource.columnCount;

    this.buildAreas(true);
  }

  public get gridResource() {
    return this.resource;
  }

  public setMousedOverArea(area:GridArea|null) {
    this.mousedOverArea = area;

    this.$mousedOverArea.next(area);
  }

  public cleanupUnusedAreas() {
    // array containing Numbers from this.numRows to 1
    let unusedRows = _.range(this.numRows, 0, -1);

    this.widgetAreas.forEach(widget => {
      unusedRows = unusedRows.filter(item => item !== widget.startRow);
    });

    unusedRows.forEach(number => {
      if (this.numRows > 1) {
        this.removeRow(number);
      }
    });

    let unusedColumns = _.range(this.numColumns, 0, -1);

    this.widgetAreas.forEach(widget => {
      unusedColumns = unusedColumns.filter(item => item !== widget.startColumn);
    });

    unusedColumns.forEach(number => {
      if (this.numColumns > 1) {
        this.removeColumn(number);
      }
    });
  }

  public buildAreas(widgets = false) {
    this.gridAreas = this.buildGridAreas();
    this.gridGaps = this.buildGridGaps();
    this.gridAreaIds = this.buildGridAreaIds();
    if (widgets) {
      this.widgetAreas = this.buildGridWidgetAreas();
    }
  }

  public rebuildAndPersist() {
    this.persist();
    this.buildAreas(false);
  }

  public persist() {
    this.resource.rowCount = this.numRows = (this.widgetAreas.map(area => area.endRow).sort().pop() || 2) - 1;
    this.resource.columnCount = this.numColumns;

    this.writeAreaChangesToWidgets();

    this.saveGrid(this.resource, this.schema);
  }

  public saveWidgetChangeset(changeset:WidgetChangeset) {
    let payload = this.gridDm.extractPayload(this.resource, this.schema);

    let payloadWidget = payload.widgets.find((w:any) => w.id === changeset.pristineResource.id);
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

  public get inHelpMode() {
    return this.helpMode || this.isSingleCell;
  }

  public toggleHelpMode() {
    this.helpMode = !this.helpMode;
  }

  // This is a hacky way to have the placeholder in the viewport.
  // It is a noop for firefox and edge as both do not support scrollIntoViewIfNeeded.
  // But as scrollIntoView will always readjust the viewport, the result would be an unbearable flicker
  // which causes e.g. dragging to be impossible.
  public scrollPlaceholderIntoView() {
    let placeholder = jQuery('.grid--area.-placeholder');

    if ((placeholder[0] as any).scrollIntoViewIfNeeded) {
      setTimeout(() => (placeholder[0] as any).scrollIntoViewIfNeeded());
    }
  }

  private saveGrid(resource:GridWidgetResource|any, schema?:SchemaResource) {
    this
      .gridDm
      .update(resource, schema)
      .then(updatedGrid => {
        this.assignAreasWidget(updatedGrid);
        this.notification.addSuccess(this.i18n.t('js.notice_successful_update'));
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

    // the one extra row is added in case the user wants to drag a widget to the very bottom
    for (let row = 1; row <= this.numRows + 1; row++) {
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

  public removeColumn(column:number) {
    this.numColumns--;

    //shrink widgets that span more than the removed column
    this.widgetAreas.forEach((widget) => {
      if (widget.startColumn <= column && widget.endColumn >= column + 1) {
        //shrink widgets that span more than the removed column
        widget.endColumn--;
      }
    });

    // move all widgets that are after the removed column
    // so that they appear to keep their place.
    this.widgetAreas.filter((widget) => {
      return widget.startColumn > column;
    }).forEach((widget) => {
      widget.startColumn--;
      widget.endColumn--;
    });
  }

  public removeRow(row:number) {
    this.numRows--;

    //shrink widgets that span more than the removed row
    this.widgetAreas.forEach((widget) => {
      if (widget.startRow <= row && widget.endRow >= row + 1) {
        //shrink widgets that span more than the removed row
        widget.endRow--;
      }
    });

    // move all widgets that are after the removed row
    // so that they appear to keep their place.
    this.widgetAreas.filter((widget) => {
      return widget.startRow > row;
    }).forEach((widget) => {
      widget.startRow--;
      widget.endRow--;
    });
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
    let index = this.resource.widgets.findIndex((widget) => widget.id === removedWidget.id );
    this.resource.widgets.splice(index, 1);

    index = this.widgetAreas.findIndex((area) => area.widget.id === removedWidget.id);
    this.widgetAreas.splice(index, 1);
    this.cleanupUnusedAreas();

    this.rebuildAndPersist();
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
