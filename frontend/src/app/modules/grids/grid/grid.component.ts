import {Component,
  OnInit,
  ComponentFactoryResolver,
  ComponentRef,
  OnDestroy,
  Input} from "@angular/core";
import {GridResource} from "app/modules/hal/resources/grid-resource";
import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {HookService} from "app/modules/plugins/hook-service";
import {debugLog} from "app/helpers/debug_output";
import {DomSanitizer} from "@angular/platform-browser";
import {CdkDragDrop, CdkDragEnter, CdkDragExit, CdkDragEnd} from "@angular/cdk/drag-drop";
import {ResizeDelta} from "../../common/resizer/resizer.component";
import {GridWidgetsService} from "app/modules/grids/widgets/widgets.service";
import {AddGridWidgetService} from "app/modules/grids/widgets/add/add.service";
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {GridArea} from "app/modules/grids/areas/grid-area";
import {GridWidgetArea} from "app/modules/grids/areas/grid-widget-area";
import {GridDmService} from "app/modules/hal/dm-services/grid-dm.service";
import {SchemaResource} from "app/modules/hal/resources/schema-resource";
import {GridMoveAreasService} from "app/modules/grids/grid/move-areas.service";

export interface WidgetRegistration {
  identifier:string;
  component:{ new (...args:any[]):AbstractWidgetComponent };
}

@Component({
  templateUrl: './grid.component.html',
  selector: 'grid',
  providers: [GridMoveAreasService]
})
export class GridComponent implements OnDestroy, OnInit {
  public uiWidgets:ComponentRef<any>[] = [];
  public widgetResources:GridWidgetResource[] = [];
  public numColumns:number = 0;
  public numRows:number = 0;
  public gridAreas:GridArea[];
  public gridWidgetAreas:GridWidgetArea[];
  public gridAreaDropIds:string[];
  public draggedArea:GridWidgetArea|null;
  public dragPlaceholderArea:GridWidgetArea|null;
  public GRID_AREA_HEIGHT = 100;

  private schema:SchemaResource;

  public resizePlaceholderArea:GridWidgetArea|null;
  private resizedArea:GridWidgetArea|null;
  public resizeAreaTargetIds:string[];
  private mousedOverArea:GridArea|null;

  @Input() grid:GridResource;

  constructor(readonly resolver:ComponentFactoryResolver,
              readonly Hook:HookService,
              private sanitization:DomSanitizer,
              private widgetsService:GridWidgetsService,
              private addService:AddGridWidgetService,
              private gridDm:GridDmService,
              private gridMoveAreas:GridMoveAreasService) {
    this.gridMoveAreas.grid = this;
  }

  ngOnDestroy() {
    this.uiWidgets.forEach((widget) => widget.destroy());
  }

  ngOnInit() {
    this.fetchSchema();

    this.numRows = this.grid.rowCount;
    this.numColumns = this.grid.columnCount;

    this.widgetResources = this.grid.widgets;

    this.buildAreas(false);
  }

  public widgetComponent(widget:GridWidgetResource|null) {
    if (!widget) {
      return null;
    }

    let registration = this.widgetsService.registered.find((reg) => reg.identifier === widget.identifier);

    if (!registration) {
      debugLog(`No widget registered with identifier ${widget.identifier}`);

      return null;
    } else {
      return registration.component;
    }
  }

  public get gridColumnStyle() {
    return this.sanitization.bypassSecurityTrustStyle(`repeat(${this.numColumns}, 1fr)`);
  }

  public get gridRowStyle() {
    return this.sanitization.bypassSecurityTrustStyle(`repeat(${this.numRows}, ${this.GRID_AREA_HEIGHT}px)`);
  }

  // array containing Numbers from 1 to this.numRows
  public get rowNumbers() {
    return Array.from(Array(this.numRows + 1).keys()).slice(1);
  }

  public get currentlyDragging() {
    return !!this.draggedArea;
  }

  public dragStart(area:GridWidgetArea) {
    this.draggedArea = area;
    this.dragPlaceholderArea = new GridWidgetArea(area.widget);
  }

  public dragStop(area:GridWidgetArea, event:CdkDragEnd) {
    if (!this.draggedArea) {
      return;
    }

    let dropArea = event.source.dropContainer.data;

    // Handle special case of user starting to move the widget but then deciding to
    // move it back to the original area.
    if (this.draggedArea.startColumn === dropArea.startColumn &&
      this.draggedArea.startRow === dropArea.startRow) {
      this.resetAreasOnDragging();
    }
    this.draggedArea = null;
    this.dragPlaceholderArea = null;
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
    if (dropArea.startRow + draggedArea.widget.height > this.numRows + 1) {
      draggedArea.endRow = this.numRows + 1;
    } else {
      draggedArea.endRow = dropArea.startRow + draggedArea.widget.height;
    }

    draggedArea.startColumn = dropArea.startColumn;
    if (dropArea.startColumn + draggedArea.widget.width > this.numColumns + 1) {
      draggedArea.endColumn = this.numColumns + 1;
    } else {
      draggedArea.endColumn = dropArea.startColumn + draggedArea.widget.width;
    }

    this.writeAreaChangesToWidgets();
    this.buildAreas();
  }

  // persist all changes to the areas caused by dragging/resizing
  // to the widget
  private writeAreaChangesToWidgets() {
    this.gridWidgetAreas.forEach((area) => {
      area.writeAreaChangeToWidget();
    });
  }

  public dragEntered(event:CdkDragEnter<GridArea>) {
    if (this.draggedArea) {
      let dropArea = event.container.data;
      this.resetAreasOnDragging(this.draggedArea);
      this.moveAreasOnDragging(dropArea);
    }
  }

  public dragExited(event:CdkDragExit<GridArea>) {
    // prevent flickering when dragging within the area spanned
    // by the dragged element. Otherwise, cdk drag fire an entered event on every
    // move.
    if (this.draggedArea) {
      this.draggedArea.endRow = this.draggedArea.startRow + 1;
      this.draggedArea.endColumn = this.draggedArea.startColumn + 1;
    }
  }

  private moveAreasOnDragging(dropArea:GridArea) {
    if (!this.dragPlaceholderArea) {
      return;
    }
    let widgetArea = this.draggedArea!;

    // we cannot use the widget's original area as moving it while dragging confuses cdkDrag
    this.dragPlaceholderArea.startRow = dropArea.startRow;
    if (this.dragPlaceholderArea.startRow + this.dragPlaceholderArea.widget.height > this.numRows + 1) {
      this.dragPlaceholderArea.endRow = this.numRows + 1;
    } else {
      this.dragPlaceholderArea.endRow = dropArea.startRow + this.dragPlaceholderArea.widget.height;
    }

    this.dragPlaceholderArea.startColumn = dropArea.startColumn;
    if (this.dragPlaceholderArea.startColumn + this.dragPlaceholderArea.widget.width > this.numColumns + 1) {
      this.dragPlaceholderArea.endColumn = this.numColumns + 1;
    } else {
      this.dragPlaceholderArea.endColumn = dropArea.startColumn + this.dragPlaceholderArea.widget.width;
    }

    this.gridMoveAreas.moveAreasDown(this.dragPlaceholderArea, widgetArea);
  }

  private resetAreasOnDragging(ignoredArea:GridWidgetArea|null = null) {
    this.gridWidgetAreas.filter((area) => {
     return !ignoredArea || area.guid !== ignoredArea.guid;
    }).forEach((area) => {
      area.startRow = area.widget.startRow;
      area.endRow = area.widget.endRow;
      area.startColumn = area.widget.startColumn;
      area.endColumn = area.widget.endColumn;
    });

    this.numRows = this.grid.rowCount;
    this.numColumns = this.grid.columnCount;
  }

  public resize(area:GridWidgetArea, deltas:ResizeDelta) {
    if (!this.resizePlaceholderArea ||
        !this.resizedArea) {
      return;
    }

    this.resizedArea.endRow = this.resizePlaceholderArea.endRow;
    this.resizedArea.endColumn = this.resizePlaceholderArea.endColumn;

    this.writeAreaChangesToWidgets();
    this.buildAreas();

    this.resizedArea = null;
    this.resizePlaceholderArea = null;
  }

  public resizeStart(resizedArea:GridWidgetArea) {
    this.resizePlaceholderArea = new GridWidgetArea(resizedArea.widget);
    this.resizedArea = resizedArea;

    let resizeTargets = this.gridAreas.filter((area) => {
      return area.startRow >= this.resizePlaceholderArea!.startRow &&
        area.startColumn >= this.resizePlaceholderArea!.startColumn; //&&
    });

    this.resizeAreaTargetIds = resizeTargets.map((area) => {
      return this.gridAreaId(area);
    });
  }

  public resizeMove(deltas:ResizeDelta) {
    if (!this.resizePlaceholderArea ||
        !this.resizedArea ||
        !this.mousedOverArea ||
        !this.resizeAreaTargetIds.includes(this.gridAreaId(this.mousedOverArea))) {
      return;
    }

    this.resetAreasOnDragging();

    this.resizePlaceholderArea.endRow = this.mousedOverArea.endRow;
    this.resizePlaceholderArea.endColumn = this.mousedOverArea.endColumn;

    this.gridMoveAreas.moveAreasDown(this.resizePlaceholderArea, this.resizedArea);
  }

  public isResizeTarget(area:GridArea) {
    let areaId = this.gridAreaId(area);

    return this.resizePlaceholderArea && this.resizeAreaTargetIds.includes(areaId);
  }

  public isAddable(area:GridArea) {
    return !this.currentlyDragging &&
             !this.currentlyResizing &&
             this.mousedOverArea === area &&
             this.gridAreaDropIds.includes(this.gridAreaId(area));
  }

  public get currentlyResizing() {
    return this.resizePlaceholderArea;
  }

  public setMousedOverArea(area:GridArea) {
    this.mousedOverArea = area;
  }

  public gridAreaId(area:GridArea) {
    return `grid--area-${area.startRow}-${area.startColumn}`;
  }

  public addWidget(area:GridArea) {
    this
      .addService
      .select(area)
      .then((widgetResource) => {
        // try to set it to a 2 x 3 layout
        // but shrink if that is outside the grid or
        // overlaps any other widget
        let newArea = new GridWidgetArea(widgetResource);

        newArea.endColumn = newArea.endColumn + 1;
        newArea.endRow = newArea.endRow + 2;

        let maxRow:number = this.numRows + 1;
        let maxColumn:number = this.numColumns + 1;

        this.gridWidgetAreas.forEach((existingArea) => {
          if (newArea.startColumnOverlaps(existingArea) &&
              maxColumn > existingArea.startColumn) {
            maxColumn = existingArea.startColumn;
          }
        });

        if (maxColumn < newArea.endColumn) {
          newArea.endColumn = maxColumn;
        }

        this.gridWidgetAreas.forEach((existingArea) => {
          if (newArea.overlaps(existingArea) &&
              maxRow > existingArea.startRow) {
            maxRow = existingArea.startRow;
          }
        });

        if (maxRow < newArea.endRow) {
          newArea.endRow = maxRow;
        }

        newArea.writeAreaChangeToWidget();

        this.widgetResources.push(newArea.widget);

        this.buildAreas();
      })
      .catch(() => {
        // user didn't select a widget
      });
  }

  public removeWidget(area:GridWidgetArea) {
    let removedWidget = area.widget;

    this.widgetResources = this.widgetResources.filter((widget) => {
      return widget.identifier !== removedWidget.identifier ||
        widget.startColumn !== removedWidget.startColumn ||
        widget.endColumn !== removedWidget.endColumn ||
        widget.startRow !== removedWidget.startRow ||
        widget.endRow !== removedWidget.endRow;
    });

    this.buildAreas();
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

  private buildAreas(save = true) {
    this.gridAreas = this.buildGridAreas();
    this.gridAreaDropIds = this.buildGridAreaDropIds();
    this.gridWidgetAreas = this.buildGridWidgetAreas();

    this.grid.widgets = this.widgetResources;
    this.grid.rowCount = this.numRows;
    this.grid.columnCount = this.numColumns;

    this.gridDm.update(this.grid, this.schema);
  }

  private fetchSchema() {
    this.gridDm.updateForm(this.grid)
      .then((form) => {
        this.schema = form.schema;
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

  public identifyGridArea(index:number, cell:GridArea) {
    return `gridArea ${cell.guid}`;
  }

  private buildGridAreaDropIds() {
    let ids:string[] = [];

    this.gridAreas.forEach((area) => {
      ids.push(this.gridAreaId(area as GridArea));
    });

    return ids;
  }
}
