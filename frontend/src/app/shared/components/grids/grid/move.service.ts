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
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';

@Injectable()
export class GridMoveService {
  private layout = inject(GridAreaService);


  public down(movedArea:GridWidgetArea|null, ignoreArea:GridWidgetArea) {
    const movedAreas:GridWidgetArea[] = [];
    let remainingAreas:GridWidgetArea[] = this.layout.widgetAreas.slice(0);

    if (ignoreArea) {
      remainingAreas = remainingAreas.filter((area) => area.guid !== ignoreArea.guid);
    }

    remainingAreas.sort((a, b) => b.startRow - a.startRow);

    while (movedArea !== null) {
      movedAreas.push(movedArea);

      remainingAreas = remainingAreas.filter((area) => area.guid !== movedArea!.guid);

      movedArea = this.moveOneDown(movedAreas, remainingAreas);
    }
  }

  private moveOneDown(anchorAreas:GridWidgetArea[], movableAreas:GridWidgetArea[]) {
    const moveSpecification = this.firstAreaToMove(anchorAreas, movableAreas);

    if (moveSpecification) {
      const toMoveArea = moveSpecification[0];
      const anchorArea = moveSpecification[1];

      const areaHeight = toMoveArea.widget.height;

      toMoveArea.startRow = anchorArea.endRow;
      toMoveArea.endRow = toMoveArea.startRow + areaHeight;

      if (this.layout.numRows < toMoveArea.endRow - 1) {
        this.layout.numRows = toMoveArea.endRow - 1;
      }

      return toMoveArea;
    }
    return null;
  }

  // Return first area that needs to move as it overlaps another area.
  // There are two groups of areas here. The first (anchorAreas) is considered stable
  // and as such not fit for being moved. This happens e.g. when the user explicitly
  // moved a widget or if the area has already been moved in a previous run of this method.
  // The second group (movableAreas) consists of all areas that are movable.
  // Once an area out of the second group has been identified that overlaps an area of the first
  // group, the appropriate reference area for later moving is selected out of the group of all
  // unmovable areas. The reference area is the bottommost area within the unmovable areas which's
  // column values (start/end) include the to move area's start column value and which's end row is larger
  // than the area overlapping the area to move. Unmovable areas which's column values do not include the
  // start column are to the left or right of the area to move and can thus be ignored.
  private firstAreaToMove(anchorAreas:GridWidgetArea[], movableAreas:GridWidgetArea[]) {
    let overlappingArea:GridWidgetArea|null = null;
    let toMoveArea:GridWidgetArea|null = null;

    movableAreas.forEach((movableArea) => {
      anchorAreas.forEach((anchorArea) => {
        if (anchorArea.overlaps(movableArea)) {
          overlappingArea = anchorArea;
          toMoveArea = movableArea;
        }
      });

      if (toMoveArea) {

      }
    });

    if (toMoveArea !== null) {
      let referenceArea = overlappingArea!;

      anchorAreas.forEach((anchorArea) => {
        if (anchorArea.endRow > referenceArea.endRow && toMoveArea!.columnOverlaps(anchorArea)) {
          referenceArea = anchorArea;
        }
      });

      return [toMoveArea, referenceArea];
    }
    return null;
  }
}
