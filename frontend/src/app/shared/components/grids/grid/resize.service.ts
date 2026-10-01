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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { GridWidgetArea } from 'core-app/shared/components/grids/areas/grid-widget-area';
import { GridArea } from 'core-app/shared/components/grids/areas/grid-area';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridMoveService } from 'core-app/shared/components/grids/grid/move.service';
import { GridDragAndDropService } from 'core-app/shared/components/grids/grid/drag-and-drop.service';

@Injectable()
export class GridResizeService {
  readonly layout = inject(GridAreaService);
  readonly move = inject(GridMoveService);
  readonly drag = inject(GridDragAndDropService);

  private resizedArea:GridWidgetArea|null;

  private targetIds:string[];

  public end(area:GridWidgetArea):Promise<GridResource>|undefined {
    if (!this.resizedArea) {
      return undefined;
    }

    this.resizedArea = null;

    // user aborted resizing
    if (area.unchangedSize) {
      return undefined;
    }

    this.layout.writeAreaChangesToWidgets();
    this.layout.cleanupUnusedAreas();

    return this.layout.rebuildAndPersist();
  }

  public abort() {
    if (this.resizedArea) {
      this.layout.resetAreas();
      this.resizedArea = null;
    }
  }

  public start(resizedArea:GridWidgetArea) {
    this.resizedArea = resizedArea;

    const resizeTargets = this.layout.gridAreas.filter((area) => {
      // All areas on the same row which are after the current column are valid targets.
      const sameRow = area.startRow === this.resizedArea!.startRow
                     && area.startColumn >= this.resizedArea!.startColumn;

      // Areas that are on higher (number, they are printed below) rows
      // are allowed as long as there is guaranteed to always be one widget
      // before or after the resized to area.
      const higherRow = area.startRow > this.resizedArea!.startRow
                      && area.startColumn >= this.resizedArea!.startColumn
                      && this.layout.widgetAreas.some((fixedArea) => fixedArea.startRow === area.startRow
                        // before
                        && (fixedArea.endColumn <= this.resizedArea!.startColumn
                          // after
                          || fixedArea.startColumn >= area.endColumn));
      return sameRow || higherRow;
    });

    this.targetIds = resizeTargets
      .map((area) => area.guid);
  }

  public moving() {
    if (!this.resizedArea
      || !this.layout.mousedOverArea
      || !this.targetIds.includes(this.layout.mousedOverArea.guid)) {
      return;
    }

    this.layout.resetAreas();

    this.resizedArea.endRow = this.layout.mousedOverArea.endRow;
    this.resizedArea.endColumn = this.layout.mousedOverArea.endColumn;

    this.move.down(this.resizedArea, this.resizedArea);
  }

  public isTarget(area:GridArea) {
    const areaId = area.guid;

    return this.resizedArea && this.targetIds.includes(areaId);
  }

  public isResized(area:GridWidgetArea) {
    return this.resizedArea?.guid === area.guid;
  }

  public isPassive(area:GridWidgetArea) {
    return this.currentlyResizing && !this.isResized(area);
  }

  public get currentlyResizing() {
    return !!this.resizedArea;
  }

  public get isResizable() {
    return !this.drag.currentlyDragging && this.isAllowed;
  }

  private get isAllowed() {
    return this.layout.gridResource.updateImmediately;
  }
}
