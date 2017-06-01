// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++
import {States} from "../../../states.service";
import {RenderInfo} from "../wp-timeline";
import {TimelineMilestoneCellRenderer} from "./timeline-milestone-cell-renderer";
import {TimelineCellRenderer} from "./timeline-cell-renderer";
import {WorkPackageTimelineTableController} from "../container/wp-timeline-container.directive";
import {$injectFields} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageTimelineCell} from "./wp-timeline-cell";
import {RenderedRow} from "../../../wp-fast-table/builders/modes/table-render-pass";

export class WorkPackageTimelineCellsRenderer {
  // Injections
  public states:States;

  public cells:{ [id:string]:WorkPackageTimelineCell } = {};

  private cellRenderers:{ milestone:TimelineMilestoneCellRenderer, generic:TimelineCellRenderer };

  constructor(private wpTimeline:WorkPackageTimelineTableController) {
    $injectFields(this, 'states');

    this.cellRenderers = {
      milestone: new TimelineMilestoneCellRenderer(wpTimeline),
      generic: new TimelineCellRenderer(wpTimeline)
    };
  }

  public hasCell(wpId:string) {
    return !!this.cells[wpId];
  }

  /**
   * Synchronize the currently active cells and render them all
   */
  public refreshAllCells() {
    // Create new cells and delete old ones
    this.synchronizeCells();

    // Update all cells
    _.each(this.cells, (cell) => this.refreshSingleCell(cell));
  }

  public refreshCellFor(wpId:string) {
    if (this.hasCell(wpId)) {
      this.refreshSingleCell(this.cells[wpId]);
    }
  }

  public refreshSingleCell(cell:WorkPackageTimelineCell) {
    const renderInfo = this.renderInfoFor(cell.workPackageId);

    if (renderInfo.workPackage) {
      cell.refreshView(renderInfo);
    }
  }

  /**
   * Synchronize the current cells:
   *
   * 1. Create new cells in workPackageIdOrder not yet tracked
   * 2. Remove old cells no longer contained.
   */
  private synchronizeCells() {
    const currentlyActive:string[] = Object.keys(this.cells);
    const newCells:string[] = [];

    _.each(this.wpTimeline.workPackageIdOrder, (renderedRow:RenderedRow) => {

      // Ignore extra rows not tied to a work package
      const wpId = renderedRow.workPackageId;
      if (!wpId) {
        return;
      }

      // Create a cell unless we already have an active cell
      if (!this.hasCell(wpId)) {
        this.cells[wpId] = this.buildCell(wpId);
      }

      newCells.push(wpId);
    });

    _.difference(currentlyActive, newCells).forEach((wpId:string) => {
      this.cells[wpId].clear();
      delete this.cells[wpId];
    });
  }

  private buildCell(wpId:string) {
    return new WorkPackageTimelineCell(
      this.wpTimeline,
      this.cellRenderers,
      this.renderInfoFor(wpId),
      wpId
    );
  }

  private renderInfoFor(wpId:string):RenderInfo {
    return {
      viewParams: this.wpTimeline.viewParameters,
      workPackage: this.states.workPackages.get(wpId).value!
    } as RenderInfo;
  }
}
