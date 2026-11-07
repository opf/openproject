//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, HostListener, Input, OnChanges, Type, inject } from '@angular/core';
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
  component:Type<AbstractWidgetComponent>;
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
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'grid',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class GridComponent implements OnChanges {
  private sanitization = inject(DomSanitizer);
  private widgetsService = inject(GridWidgetsService);
  drag = inject(GridDragAndDropService);
  resize = inject(GridResizeService);
  layout = inject(GridAreaService);
  add = inject(GridAddWidgetService);
  remove = inject(GridRemoveWidgetService);
  readonly browserDetector = inject(BrowserDetector);

  public GRID_AREA_HEIGHT = 'auto';

  public GRID_GAP_DIMENSION = '20px';

  public component = WidgetWpGraphComponent;

  @Input() grid:GridResource;

  ngOnChanges() {
    if (this.drag.currentlyDragging) {
      this.drag.abort();
    }
    if (this.resize.currentlyResizing) {
      this.resize.abort();
    }
    this.layout.initialize(this.grid);
  }

  // Cancellation happens on keyup; the keydown half would otherwise clear
  // an embedded table's selection first.
  @HostListener('body:keydown', ['$event'])
  consumeEscapeWhileInteracting(event:KeyboardEvent) {
    if (event.key === 'Escape' && (this.drag.currentlyDragging || this.resize.currentlyResizing)) {
      event.preventDefault();
    }
  }

  @HostListener('window:keyup', ['$event'])
  handleKeyboardEvent(event:KeyboardEvent) {
    if (event.key !== 'Escape') {
      return;
    }

    if (this.drag.currentlyDragging) {
      this.drag.abort();
    } else if (this.resize.currentlyResizing) {
      this.resize.abort();
    }
  }

  public addWidget(area:GridWidgetArea|GridArea) {
    void this.add.widget(area);
  }

  public resizeEnd(area:GridWidgetArea) {
    void this.resize.end(area)?.catch(() => undefined);
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
        void this.layout.saveWidgetChangeset(changeset).catch(() => undefined);
      },
    };
  }

  public get gridColumnStyle() {
    return this.gridStyle(this.layout.numColumns(),
      `calc((100% - ${this.GRID_GAP_DIMENSION} * ${this.layout.numColumns() + 1}) / ${this.layout.numColumns()})`);
  }

  public get gridRowStyle() {
    return this.gridStyle(this.layout.numRows(),
      this.GRID_AREA_HEIGHT);
  }

  public identifyGridArea(index:number, area:GridArea) {
    return area.guid;
  }

  public get isHeadersDisplayed() {
    return this.layout.isEditable();
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
