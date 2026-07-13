import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ComponentRef, HostListener, Input, OnDestroy, OnInit, inject } from '@angular/core';
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
import { WidgetChangeset } from 'core-app/shared/components/grids/widgets/widget-changeset';

export interface WidgetRegistration {
  identifier:string;
  title:string;
  component:new (...args:any[]) => AbstractWidgetComponent;
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
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class GridComponent implements OnDestroy, OnInit {
  private sanitization = inject(DomSanitizer);
  private widgetsService = inject(GridWidgetsService);
  drag = inject(GridDragAndDropService);
  resize = inject(GridResizeService);
  layout = inject(GridAreaService);
  add = inject(GridAddWidgetService);
  remove = inject(GridRemoveWidgetService);
  readonly browserDetector = inject(BrowserDetector);
  readonly cdRef = inject(ChangeDetectorRef);

  public uiWidgets:ComponentRef<any>[] = [];

  public GRID_AREA_HEIGHT = 'auto';

  public GRID_GAP_DIMENSION = '20px';

  public component = WidgetWpGraphComponent;

  @Input() grid:GridResource;

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
    this.detectChangesAfter(this.add.widget(area));
  }

  public resizeEnd(area:GridWidgetArea) {
    this.detectChangesAfter(this.resize.end(area));
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

  public widgetComponentOutput(_area:GridWidgetArea) {
    return {
      resourceChanged: (changeset:WidgetChangeset) => {
        this.detectChangesAfter(this.layout.saveWidgetChangeset(changeset));
      },
    };
  }

  public get gridColumnStyle() {
    return this.gridStyle(this.layout.numColumns,
      `calc((100% - ${this.GRID_GAP_DIMENSION} * ${this.layout.numColumns + 1}) / ${this.layout.numColumns})`);
  }

  public get gridRowStyle() {
    return this.gridStyle(this.layout.numRows,
      this.GRID_AREA_HEIGHT);
  }

  public get widgetAreasForDisplay():GridWidgetArea[] {
    // Convert a 2D grid position to a flat linear index so widgets can be
    // sorted by visual order (left-to-right, top-to-bottom) instead of their
    // insertion order. Multiplying by numColumns ensures each row starts at a
    // higher index than all cells of the previous row (e.g. for 3 columns:
    // row 1 → 1–3, row 2 → 4–6, …). startRow is 1-based, hence the "- 1".
    const index = (a:GridWidgetArea) =>
      (a.startRow - 1) * this.layout.numColumns + a.startColumn;

    const key = (a:GridWidgetArea) =>
      (a.widget?.id ?? a.guid).toString();

    return [...(this.layout.widgetAreas || [])].sort((a, b) => {
      const diff = index(a) - index(b);
      return diff !== 0 ? diff : key(a).localeCompare(key(b));
    });
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

  private detectChangesAfter<T>(promise:Promise<T>|undefined) {
    void promise
      ?.finally(() => this.cdRef.detectChanges())
      .catch(() => undefined);
  }
}
