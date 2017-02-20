// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
import IDirective = angular.IDirective;
import IComponentOptions = angular.IComponentOptions;
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {RenderInfo, TimelineViewParameters, timelineElementCssClass} from "./wp-timeline";
import {WorkPackageTimelineCell} from "./wp-timeline-cell";


export const timelineGlobalElementCssClassname = "timeline-global-element";


export class TimelineGlobalElement {
  from: string;
  to: string;
}

export class WpTimelineGlobalService {

  private workPackageIdOrder: string[] = ["56", "55", "54"];

  private cells: {[id: string]: WorkPackageTimelineCell} = {};

  private elements: TimelineGlobalElement[] = [];

  constructor() {
    setTimeout(() => {
      console.log("displayRelation");
      this.displayRelation("55", "54");
    }, 3000);
  }

  updateWorkPackageInfo(cell: WorkPackageTimelineCell) {
    this.cells[cell.latestRenderInfo.workPackage.id] = cell;

    // TODO called to often

    this.update();
  }

  removeWorkPackageInfo(id: string) {
    delete this.cells[id];
    this.update()
  }

  displayRelation(from: string, to: string) {
    const elem = new TimelineGlobalElement();
    elem.from = from;
    elem.to = to;
    this.elements.push(elem);
    this.update();
  }

  private update() {
    this.removeAllElements();
    this.renderElements();
  }

  private removeAllElements() {
    // console.log("removeAllElements()");
    jQuery("." + timelineGlobalElementCssClassname).children().remove();
  }

  private renderElements() {
    console.debug("renderElements()");

    for (let e of this.elements) {

      const idxFrom = this.workPackageIdOrder.indexOf(e.from);
      const idxTo = this.workPackageIdOrder.indexOf(e.to);
      const start = Math.min(idxFrom, idxTo);
      const end = Math.max(idxFrom, idxTo);

      // start
      const startCell = this.cells[e.from];
      let lastX = startCell.getRightmostPosition();

      const line = document.createElement("div");
      line.className = timelineElementCssClass;
      line.style.position = "absolute";
      line.style.zIndex = "100";
      line.style.cssFloat = "left";
      line.style.backgroundColor = "green";
      line.style.top = "19px";
      line.style.left = lastX + "px";
      line.style.width = "20px";
      lastX += 20;
      line.style.height = "2px";
      startCell.timelineCell.appendChild(line);

      // vert line
      for (let index = start; index <= end; index++) {
        const id = this.workPackageIdOrder[index];
        const cell = this.cells[id];

        // console.log("i", index, id, cell);
      }
    }

  }

}

