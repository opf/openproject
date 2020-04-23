import {Component,
  ComponentRef,
  OnDestroy,
  OnInit,
  Input,
  HostListener} from "@angular/core";
import {GridResource} from "app/modules/hal/resources/grid-resource";
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
import {BrowserDetector} from "core-app/modules/common/browser/browser-detector.service";

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
  public GRID_GAP_DIMENSION = '20px';

  public component = WidgetWpGraphComponent;

  @Input() grid:GridResource;

  constructor(private sanitization:DomSanitizer,
              private widgetsService:GridWidgetsService,
              public drag:GridDragAndDropService,
              public resize:GridResizeService,
              public layout:GridAreaService,
              public add:GridAddWidgetService,
              public remove:GridRemoveWidgetService,
              readonly browserDetector:BrowserDetector) {
  }

  ngOnInit() {
    this.layout.gridResource = this.grid;
  }

  ngOnDestroy() {
    this.uiWidgets.forEach((widget) => widget.destroy());
  }

  @HostListener('window:keyup', ['$event'])
  handleKeyboardEvent(event:KeyboardEvent) {
    if (event.key !== 'Escape') {
      return;
    } else if (this.drag.currentlyDragging) {
      this.drag.abort();
    } else if (this.resize.currentlyResizing) {
      this.resize.abort();
    }
  }

  public widgetComponent(area:GridWidgetArea) {
    let widget = area.widget;

    if (!widget) {
      return null;
    }

    let registration = this.widgetsService.registered.find((reg) => reg.identifier === widget.identifier);

    if (!registration) {
      // debugLog(`No widget registered with identifier ${widget.identifier}`);

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
    return this.gridStyle(this.layout.numColumns,
                          `calc((100% - ${this.GRID_GAP_DIMENSION} * ${this.layout.numColumns + 1}) / ${this.layout.numColumns})`);
  }

  public get gridRowStyle() {
    return this.gridStyle(this.layout.numRows,
                         this.GRID_AREA_HEIGHT);
  }

  public identifyGridArea(index:number, area:GridArea) {
    return area.guid;
  }

  public get isHeadersDisplayed() {
    return this.layout.isEditable;
  }

  public get isMobileDevice() {
    return this.browserDetector.isMobile;
  }

  private gridStyle(amount:number, itemStyle:string) {
    let style = '';
    for (let i = 0; i < amount; i++) {
      style += `${this.GRID_GAP_DIMENSION} ${itemStyle} `;
    }

    style += `${this.GRID_GAP_DIMENSION}`;

    return this.sanitization.bypassSecurityTrustStyle(style);
  }
}
