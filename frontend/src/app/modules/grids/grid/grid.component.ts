import {Component,
  ComponentRef,
  OnDestroy,
  OnInit,
  Input} from "@angular/core";
import {GridResource} from "app/modules/hal/resources/grid-resource";
import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {debugLog} from "app/helpers/debug_output";
import {DomSanitizer} from "@angular/platform-browser";
import {GridWidgetsService} from "app/modules/grids/widgets/widgets.service";
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {GridArea} from "app/modules/grids/areas/grid-area";
import {GridWidgetArea} from "app/modules/grids/areas/grid-widget-area";
import {GridMoveService} from "app/modules/grids/grid/move.service";
import {GridDragAndDropService} from "core-app/modules/grids/grid/drag-and-drop.service";
import {GridResizeService} from "core-app/modules/grids/grid/resize.service";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {GridAddWidgetService} from "core-app/modules/grids/grid/add-widget.service";
import {GridRemoveWidgetService} from "core-app/modules/grids/grid/remove-widget.service";

export interface WidgetRegistration {
  identifier:string;
  component:{ new (...args:any[]):AbstractWidgetComponent };
}

@Component({
  templateUrl: './grid.component.html',
  selector: 'grid',
  providers: [
    GridAreaService,
    GridMoveService,
    GridDragAndDropService,
    GridResizeService,
    GridAddWidgetService,
    GridRemoveWidgetService
  ]
})
export class GridComponent implements OnDestroy, OnInit {
  public uiWidgets:ComponentRef<any>[] = [];
  public GRID_AREA_HEIGHT = 100;

  @Input() grid:GridResource;

  constructor(private sanitization:DomSanitizer,
              private widgetsService:GridWidgetsService,
              public drag:GridDragAndDropService,
              public resize:GridResizeService,
              public layout:GridAreaService,
              public add:GridAddWidgetService,
              public remove:GridRemoveWidgetService) {
  }

  ngOnInit() {
    this.layout.gridResource = this.grid;
  }

  ngOnDestroy() {
    this.uiWidgets.forEach((widget) => widget.destroy());
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
    return this.sanitization.bypassSecurityTrustStyle(`repeat(${this.layout.numColumns}, 1fr)`);
  }

  // array containing Numbers from 1 to this.numColumns
  public get columnNumbers() {
    return Array.from(Array(this.layout.numColumns + 1).keys()).slice(1);
  }

  public get gridRowStyle() {
    return this.sanitization.bypassSecurityTrustStyle(`repeat(${this.layout.numRows}, ${this.GRID_AREA_HEIGHT}px)`);
  }

  public get rowNumbers() {
    return Array.from(Array(this.layout.numRows + 1).keys()).slice(1);
  }

  public identifyGridArea(index:number, area:GridArea) {
    return area.guid;
  }
}
