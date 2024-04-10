import { ChangeDetectorRef, Component, ComponentRef, HostListener, Input, OnDestroy, OnInit } from '@angular/core';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { DomSanitizer } from '@angular/platform-browser';
import { GridWidgetsService } from 'core-app/shared/components/grids/widgets/widgets.service';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { GridArea } from 'core-app/shared/components/grids/areas/grid-area';
import { GridMoveService } from 'core-app/shared/components/grids/grid/move.service';
import { GridDragAndDropService } from 'core-app/shared/components/grids/grid/drag-and-drop.service';
import { GridResizeService } from 'core-app/shared/components/grids/grid/resize.service';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridAddWidgetService } from 'core-app/shared/components/grids/grid/add-widget.service';
import { GridRemoveWidgetService } from 'core-app/shared/components/grids/grid/remove-widget.service';
import { WidgetWpGraphComponent } from 'core-app/shared/components/grids/widgets/wp-graph/wp-graph.component';
import { GridWidgetArea } from 'core-app/shared/components/grids/areas/grid-widget-area';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';

export interface WidgetRegistration {
  identifier:string;
  title:string;
  component:{ new (...args:any[]):AbstractWidgetComponent };
  properties?:Record<string, unknown>;
}

export const GRID_PROVIDERS = [
  GridAreaService,
  GridMoveService,
  GridDragAndDropService,
  GridResizeService,
  GridAddWidgetService,
  GridRemoveWidgetService,
];

@Component({
  templateUrl: './grid.component.html',
  selector: 'grid',
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
    readonly browserDetector:BrowserDetector,
    readonly cdRef:ChangeDetectorRef,
  ) {
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

    } else if (this.drag.currentlyDragging) {
      this.drag.abort();
    } else if (this.resize.currentlyResizing) {
      this.resize.abort();
    }
  }

  public addWidget(area:GridWidgetArea|GridArea) {
    void this
      .add
      .widget(area)
      .then(() => this.cdRef.detectChanges());
  }

  public widgetComponent(area:GridWidgetArea) {
    const { widget } = area;

    if (!widget) {
      return null;
    }

    const registration = this.widgetsService.registered.find((reg) => reg.identifier === widget.identifier);

    if (!registration) {
      // debugLog(`No widget registered with identifier ${widget.identifier}`);

      return null;
    }
    return registration.component;
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
