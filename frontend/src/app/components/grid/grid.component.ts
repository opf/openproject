import {Component, OnInit, AfterViewInit, ComponentFactoryResolver, ElementRef, ViewChild, ViewContainerRef,
  ComponentRef,
  OnDestroy,
  ReflectiveInjector,
  Injector} from "@angular/core";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {HookService} from "core-app/modules/plugins/hook-service";
import {debugLog} from "core-app/helpers/debug_output";
import {DomSanitizer} from "@angular/platform-browser";
import {AbstractWidgetComponent} from "core-components/grid/widgets/abstract-widget.component";
import {CdkDragDrop, CdkDragStart, CdkDragEnd} from "@angular/cdk/drag-drop";
import {ResizeDelta} from "../../modules/common/resizer/resizer.component";

export interface WidgetRegistration {
  identifier:string;
  // TODO: Find out how to declare component to be of type class
  component:any;
}

interface GridArea {
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
export class GridComponent implements OnInit, AfterViewInit, OnDestroy {
  public uiWidgets:ComponentRef<any>[] = [];
  private registeredWidgets:WidgetRegistration[] = [];
  public widgetResources:GridWidgetResource[] = [];
  private numColumns:number = 0;
  private numRows:number = 0;
  public gridAreas:GridArea[];
  public gridAreaDropIds:string[];
  public currentlyDragging = false;
  public GRID_AREA_HEIGHT = 400;

  public areaResources = [{component: AbstractWidgetComponent}];

  public resizeArea:GridArea|null;
  private mousedOverArea:GridArea|null;

  constructor(readonly gridDm:GridDmService,
              readonly resolver:ComponentFactoryResolver,
              readonly Hook:HookService,
              private sanitization:DomSanitizer,
              private injector:Injector) {}

  ngOnInit() {
    _.each(this.Hook.call('gridWidgets'), (registration:WidgetRegistration[]) => {
      this.registeredWidgets = this.registeredWidgets.concat(registration);
    });
  }

  ngOnDestroy() {
    this.uiWidgets.forEach((widget) => widget.destroy());
  }

  ngAfterViewInit() {
    this.gridDm.load().then((grid:GridResource) => {
      this.numRows = grid.rowCount;
      this.numColumns = grid.columnCount;

      this.widgetResources = grid.widgets;

      this.gridAreas = this.buildGridAreas();
      this.gridAreaDropIds = this.buildGridAreaDropIds();
    });
  }

  public widgetComponent(widget:GridWidgetResource|null) {
    if (!widget) {
      return null;
    }

    let registration = this.registeredWidgets.find((reg) => reg.identifier === widget.identifier);

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
      let width = parseInt(widget.endColumn) - parseInt(widget.startColumn);
      let height = parseInt(widget.endRow) - parseInt(widget.startRow);

      widget.startRow = event.container.data.startRow.toString();
      widget.endRow = (parseInt(widget.startRow) + height).toString();
      widget.startColumn = event.container.data.startColumn.toString();
      widget.endColumn = (parseInt(widget.startColumn) + width).toString();
    }

    this.gridAreas = this.buildGridAreas();
    this.gridAreaDropIds = this.buildGridAreaDropIds();
  }

  public resize(area:GridArea, deltas:ResizeDelta) {
    if (!this.resizeArea || !this.mousedOverArea) {
      return;
    }

    if (this.mousedOverArea !== this.resizeArea) {
      area.endRow = this.mousedOverArea.endRow;
      area.endColumn = this.mousedOverArea.endColumn;
    }

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
    if (!this.resizeArea || !this.mousedOverArea) {
      return;
    }

    if (this.mousedOverArea !== this.resizeArea) {
      this.resizeArea.endRow = this.mousedOverArea.endRow;
      this.resizeArea.endColumn = this.mousedOverArea.endColumn;
    }
  }

  public setMousedOverArea(area:GridArea) {
    this.mousedOverArea = area;
    console.log(area.startRow);
    console.log(area.startColumn);
  }

  public gridAreaId(area:GridArea) {
    return `grid--area-${area.startRow}-${area.startColumn}`;
  }

  public buildGridAreas() {
    let cells:GridArea[] = [];

    for (let row = 1; row <= this.numRows; row++) {
      for (let column = 1; column <= this.numColumns; column++) {
        let widget = this.widgetOfArea(row, column);
        let cell = { startRow: row,
                     endRow: widget && parseInt(widget.endRow) || row + 1,
                     startColumn: column,
                     endColumn: widget && parseInt(widget.endColumn) || column + 1,
                     widget: widget || null };

        cells.push(cell);
      }
    }

    return cells;
  }

  private widgetOfArea(row:number, column:number) {
    return this.widgetResources.find((resource) => parseInt(resource.startRow) === row && parseInt(resource.startColumn) === column);
  }

  public identifyGridCellItem(index:number, cell:GridArea) {
    return `gridItem ${cell.startRow}/${cell.endColumn}`;
  }

  public identifyWidgetResource(index:number, item:GridWidgetResource) {
    return `${item.identifier} ${item.startRow}/${item.startColumn}`;
  }

  public buildGridAreaDropIds() {
    let ids:string[] = [];

    this.gridAreas.filter((area) => {
      return !this.widgetResources.find((resource) => {
        return parseInt(resource.startRow) <= area.startRow &&
          parseInt(resource.endRow) >= area.endRow &&
          parseInt(resource.startColumn) <= area.startColumn &&
          parseInt(resource.endColumn) >= area.endColumn;
      });
    }).forEach((area) => {
      ids.push(this.gridAreaId(area as GridArea));
    });

    return ids;
  }
}
