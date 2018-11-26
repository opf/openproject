import {Component, OnInit, AfterViewInit, ComponentFactoryResolver, ElementRef, ViewChild, ViewContainerRef,
  ComponentRef,
  OnDestroy,
  Input} from "@angular/core";
import {GridResource} from "app/modules/hal/resources/grid-resource";
import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {HookService} from "app/modules/plugins/hook-service";
import {debugLog} from "app/helpers/debug_output";
import {DomSanitizer} from "@angular/platform-browser";
import {CdkDragDrop, CdkDragStart, CdkDragEnd} from "@angular/cdk/drag-drop";
import {ResizeDelta} from "../common/resizer/resizer.component";
import {GridWidgetsService} from "core-app/modules/grids/widgets/widgets.service";
import {AddGridWidgetService} from "core-app/modules/grids/widgets/add/add.service";
import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";

export interface WidgetRegistration {
  identifier:string;
  // TODO: Find out how to declare component to be of type class
  component:any;
}

export interface GridArea {
  startRow:number;
  endRow:number;
  startColumn:number;
  endColumn:number;
  widget:GridWidgetResource|null;
}

@Component({
  templateUrl: './grid.component.html',
  selector: 'grid'
})
export class GridComponent implements OnDestroy, OnInit {
  public uiWidgets:ComponentRef<any>[] = [];
  public widgetResources:GridWidgetResource[] = [];
  private numColumns:number = 0;
  private numRows:number = 0;
  public gridAreas:GridArea[];
  public gridWidgetAreas:GridArea[];
  public gridAreaDropIds:string[];
  public currentlyDragging = false;
  public GRID_AREA_HEIGHT = 400;

  public resizeArea:GridArea|null;
  private mousedOverArea:GridArea|null;

  @Input() grid:GridResource;

  constructor(readonly resolver:ComponentFactoryResolver,
              readonly Hook:HookService,
              private sanitization:DomSanitizer,
              private widgetsService:GridWidgetsService,
              private addService:AddGridWidgetService) {}

  ngOnDestroy() {
    this.uiWidgets.forEach((widget) => widget.destroy());
  }

  ngOnInit() {
    this.numRows = this.grid.rowCount;
    this.numColumns = this.grid.columnCount;

    this.widgetResources = this.grid.widgets;

    this.buildAreas();
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

  public dragStart(event:CdkDragStart) {
    this.currentlyDragging = true;
  }

  public dragStop(event:CdkDragEnd) {
    this.currentlyDragging = false;
  }

  public drop(event:CdkDragDrop<GridArea>) {
    if (event.previousContainer === event.container) {
      //nothing
    } else {
      let widget = event.previousContainer.data.widget as GridWidgetResource;
      let dropArea = event.container.data;
      let width = widget.width;
      let height = widget.height;

      widget.startRow = dropArea.startRow;
      widget.endRow = widget.startRow + height;
      widget.startColumn = dropArea.startColumn;
      widget.endColumn = widget.startColumn + width;
    }

    this.buildAreas();
  }

  public resize(area:GridArea, deltas:ResizeDelta) {
    if (!this.resizeArea ||
        !this.mousedOverArea ||
        this.mousedOverArea === this.resizeArea) {
      return;
    }

    let widget = area.widget!;

    widget.endRow = this.resizeArea.endRow;
    widget.endColumn = this.resizeArea.endColumn;

    this.buildAreas();

    return this.resizeArea = null;
  }

  public resizeStart(area:GridArea) {
    this.resizeArea = {
      startRow: area.startRow,
      endRow: area.endRow,
      startColumn: area.startColumn,
      endColumn: area.endColumn,
      widget: null
    };
  }

  public resizeMove(deltas:ResizeDelta) {
    if (!this.resizeArea ||
        !this.mousedOverArea ||
        this.mousedOverArea === this.resizeArea) {
      return;
    }

    this.resizeArea.endRow = this.mousedOverArea.endRow;
    this.resizeArea.endColumn = this.mousedOverArea.endColumn;
  }

  public isResizeTarget(area:GridArea) {
    if (!this.resizeArea) {
      return false;
    } else if (this.gridAreaDropIds.indexOf(this.gridAreaId(area)) >= 0) {
      return true;
    } else {
      return area.startRow >= this.resizeArea.startRow &&
             area.endRow <= this.resizeArea.endRow &&
             area.startColumn >= this.resizeArea.startColumn &&
             area.endColumn <= this.resizeArea.endColumn;
    }
  }

  public isAddable(area:GridArea) {
    return !this.currentlyDragging &&
             !this.currentlyResizing &&
             this.mousedOverArea === area &&
             this.gridAreaDropIds.includes(this.gridAreaId(area));
  }

  public get currentlyResizing() {
    return this.resizeArea;
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
        // TODO: We should use the proper resource here
        // but they are not casted as such when we get the
        // initial resources from the backend
        this.widgetResources.push(widgetResource);

        this.buildAreas();
      });
  }

  public removeWidget(area:GridArea) {
    let removedWidget = area.widget!;

    this.widgetResources = this.widgetResources.filter((widget) => {
      return widget.identifier !== removedWidget.identifier ||
        widget.startColumn !== removedWidget.startColumn ||
        widget.endColumn !== removedWidget.endColumn ||
        widget.startRow !== removedWidget.startRow ||
        widget.endRow !== removedWidget.endRow;
    });

    this.buildAreas();
  }

  private buildAreas() {
    this.gridAreas = this.buildGridAreas();
    this.gridAreaDropIds = this.buildGridAreaDropIds();
    this.gridWidgetAreas = this.buildWidgetGridAreas();
  }

  private buildGridAreas() {
    let cells:GridArea[] = [];

    for (let row = 1; row <= this.numRows; row++) {
      for (let column = 1; column <= this.numColumns; column++) {
        let widget = this.widgetOfArea(row, column);

        let cell = { startRow: row,
                     endRow: row + 1,
                     startColumn: column,
                     endColumn: column + 1,
                     widget: null };

        cells.push(cell);
      }
    }

    return cells;
  }

  private buildWidgetGridAreas() {
    let cells:GridArea[] = [];

    for (let row = 1; row <= this.numRows; row++) {
      for (let column = 1; column <= this.numColumns; column++) {
        let widget = this.widgetOfArea(row, column);

        if (widget) {
          let cell = {
            startRow: row,
            endRow: widget.endRow,
            startColumn: column,
            endColumn: widget.endColumn,
            widget: widget
          };

          cells.push(cell);
        }
      }
    }

    return cells;
  }

  private widgetOfArea(row:number, column:number) {
    return this.widgetResources.find((resource) => resource.startRow === row && resource.startColumn === column);
  }

  public identifyGridCellItem(index:number, cell:GridArea) {
    return `gridItem ${cell.startRow}/${cell.endColumn}`;
  }

  public identifyWidgetResource(index:number, item:GridWidgetResource) {
    return `${item.identifier} ${item.startRow}/${item.startColumn}`;
  }

  private buildGridAreaDropIds() {
    let ids:string[] = [];

    this.gridAreas.filter((area) => {
      return !this.widgetResources.find((resource) => {
        return resource.startRow <= area.startRow &&
          resource.endRow >= area.endRow &&
          resource.startColumn <= area.startColumn &&
          resource.endColumn >= area.endColumn;
      });
    }).forEach((area) => {
      ids.push(this.gridAreaId(area as GridArea));
    });

    return ids;
  }
}
