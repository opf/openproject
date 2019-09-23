import {Component,
  ComponentRef,
  OnDestroy,
  OnInit,
  Input} from "@angular/core";
import {GridResource} from "app/modules/hal/resources/grid-resource";
import {debugLog} from "app/helpers/debug_output";
import {DomSanitizer} from "@angular/platform-browser";
import {GridWidgetsService} from "app/modules/grids/widgets/widgets.service";
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {GridArea} from "app/modules/grids/areas/grid-area";
import {GridMoveService} from "app/modules/grids/grid/move.service";
import {GridDragAndDropService} from "core-app/modules/grids/grid/drag-and-drop.service";
import {GridResizeService} from "core-app/modules/grids/grid/resize.service";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import {GridAddWidgetService} from "core-app/modules/grids/grid/add-widget.service";
import {GridRemoveWidgetService} from "core-app/modules/grids/grid/remove-widget.service";
import {WidgetWpGraphComponent} from "core-app/modules/grids/widgets/wp-graph/wp-graph.component";
import {GridWidgetArea} from "core-app/modules/grids/areas/grid-widget-area";

export interface WidgetRegistration {
  identifier:string;
  title:string;
  component:{ new (...args:any[]):AbstractWidgetComponent };
  properties?:any;
}

export const GRID_PROVIDERS = [
  GridAreaService,
  GridMoveService,
  GridDragAndDropService,
  GridResizeService,
  GridAddWidgetService,
  GridRemoveWidgetService
];

@Component({
  templateUrl: './grid.component.html',
  selector: 'grid'
})
export class GridComponent implements OnDestroy, OnInit {
  public uiWidgets:ComponentRef<any>[] = [];
  public GRID_AREA_HEIGHT = 'auto';

  public component = WidgetWpGraphComponent;

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

  public widgetComponent(area:GridWidgetArea) {
    let widget = area.widget;

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

  public widgetComponentInput(area:GridWidgetArea) {
    return { resource: area.widget };
  }

  public widgetComponentOutput(area:GridWidgetArea) {
    return { resourceChanged: this.layout.saveWidgetChangeset.bind(this.layout) };
  }

  public get gridColumnStyle() {
    let style = '';
    for (let i = 0; i < this.layout.numColumns; i++) {
      style += `20px calc((100% - 20px * ${this.layout.numColumns + 1}) / ${this.layout.numColumns}) `;
    }

    style += '20px';

    return this.sanitization.bypassSecurityTrustStyle(style);
  }

  // array containing Numbers from 1 to this.numColumns
  public get columnNumbers() {
    return Array.from(Array(this.layout.numColumns + 1).keys()).slice(1);
  }

  public get gridRowStyle() {
    return this.sanitization.bypassSecurityTrustStyle(`repeat(${this.layout.numRows}, ${this.GRID_AREA_HEIGHT})`);
  }

  public get rowNumbers() {
    return Array.from(Array(this.layout.numRows + 1).keys()).slice(1);
  }

  public identifyGridArea(index:number, area:GridArea) {
    return area.guid;
  }

  public get isHeadersDisplayed() {
    return this.layout.isEditable;
  }
}
