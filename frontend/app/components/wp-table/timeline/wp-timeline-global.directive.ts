
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
import {timelineElementCssClass, TimelineViewParameters} from "./wp-timeline";
import {WorkPackageTimelineCell} from "./wp-timeline-cell";
import {States} from "../../states.service";
import {HalRequestService} from "../../api/api-v3/hal-request/hal-request.service";
import {RelationResource} from "../../api/api-v3/hal-resources/relation-resource.service";
import {CollectionResource} from "../../api/api-v3/hal-resources/collection-resource.service";
import {debugLog} from "../../../helpers/debug_output";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";
import IScope = angular.IScope;


export const timelineGlobalElementCssClassname = 'timeline-global-element';

function newSegment(vp: TimelineViewParameters,
                    classId: string,
                    color: string,
                    top: number,
                    left: number,
                    width: number,
                    height: number): HTMLElement {

  const segment = document.createElement('div');
  segment.classList.add(timelineElementCssClass, timelineGlobalElementCssClassname, classId);
  segment.style.position = 'absolute';
  segment.style.cssFloat = 'left';
  segment.style.backgroundColor = 'blue';
  // segment.style.backgroundColor = color;
  segment.style.marginLeft = vp.scrollOffsetInPx + 'px';
  segment.style.top = top + 'px';
  segment.style.left = left + 'px';
  segment.style.width = width + 'px';
  segment.style.height = height + 'px';
  return segment;
}

export class TimelineGlobalElement {

  static readonly timelineGlobalElementIdCssClass = "timeline-global-element-id-";

  private static nextId = 0;

  readonly id = TimelineGlobalElement.nextId++;

  readonly classId = TimelineGlobalElement.timelineGlobalElementIdCssClass + this.id;

  from: string;

  to: string;

}

export class WpTimelineGlobalService {

  private workPackageIdOrder: string[] = [];

  private viewParameters: TimelineViewParameters;

  private cells: {[id: string]: WorkPackageTimelineCell} = {};

  private elements: TimelineGlobalElement[] = [];

  constructor(scope: IScope, states: States, halRequest: HalRequestService) {
    states.table.rows.observeOnScope(scope)
      .subscribe(rows => {
        this.workPackageIdOrder = rows.map(wp => wp.id.toString());

        halRequest.get(
          '/api/v3/relations',
          {
            filters: JSON.stringify([{ involved: {operator: '=', values: this.workPackageIdOrder } }])
          }).then((collection: CollectionResource) => {
            this.removeAllElements();
            collection.elements.forEach((relation: RelationResource) => {
              const fromId = WorkPackageResource.idFromLink(relation.from.href!);
              const toId = WorkPackageResource.idFromLink(relation.to.href!);
              this.displayRelation(fromId, toId);
            });
            this.renderElements();
          });
      });
  }

  updateViewParameter(viewParams: TimelineViewParameters) {
    this.viewParameters = viewParams;
    this.update();
  }

  updateWorkPackageInfo(cell: WorkPackageTimelineCell) {
    this.cells[cell.latestRenderInfo.workPackage.id] = cell;
    this.update();
  }

  removeWorkPackageInfo(id: string) {
    delete this.cells[id];
    this.update();
  }

  displayRelation(from: string, to: string): number {
    const elem = new TimelineGlobalElement();
    elem.from = from;
    elem.to = to;
    this.elements.push(elem);
    this.update();
    return elem.id;
  }

  removeElement(id: number) {
    jQuery("." + TimelineGlobalElement.timelineGlobalElementIdCssClass + id).remove();
    _.remove(this.elements, elem => elem.id == id);
  }

  private update() {
    this.removeAllVisibleElements();
    this.renderElements();
  }

  private removeAllElements() {
    this.removeAllVisibleElements();
    this.elements = [];
  }

  private removeAllVisibleElements() {
    jQuery('.' + timelineGlobalElementCssClassname).remove();
  }

  private renderElements() {
    if (this.viewParameters === undefined) {
      debugLog('renderElements() aborted - no viewParameters');
      return;
    }

    const vp = this.viewParameters;

    for (let e of this.elements) {
      jQuery('.' + e.classId).remove();

      const idxFrom = this.workPackageIdOrder.indexOf(e.from);
      const idxTo = this.workPackageIdOrder.indexOf(e.to);

      const startCell = this.cells[e.from];
      const endCell = this.cells[e.to];

      if (idxFrom === -1 || idxTo === -1 || _.isNil(startCell) || _.isNil(endCell)) {
        continue;
      }

      if (!startCell.canConnectRelations() || !endCell.canConnectRelations()) {
        continue;
      }

      const directionY = idxFrom < idxTo ? 1 : -1;
      let lastX = startCell.getRightmostPosition();
      let targetX = endCell.getLeftmostPosition();
      const directionX = targetX >= lastX ? 1 : -1;

      // start
      if (!startCell) {
        continue;
      }

      const startLength = 13;
      startCell.timelineCell.appendChild(newSegment(vp, e.classId, 'green', 19, lastX, startLength, 1));
      lastX += startLength;

      if (directionY === 1) {
        startCell.timelineCell.appendChild(newSegment(vp, e.classId, 'red', 19, lastX, 1, 22));
      } else {
        startCell.timelineCell.appendChild(newSegment(vp, e.classId, 'red', -1, lastX, 1, 22));
      }

      // vert segment
      for (let index = idxFrom + directionY; index !== idxTo; index += directionY) {
        const id = this.workPackageIdOrder[index];
        const cell = this.cells[id];
        if (_.isNil(cell)) {
          continue;
        }
        cell.timelineCell.appendChild(newSegment(vp, e.classId, 'blue', 0, lastX, 1, 42));
      }

      // end
      if (directionX === 1) {
        if (directionY === 1) {
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'green', 0, lastX, 1, 19));
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'blue', 19, lastX, targetX - lastX, 1));
        } else {
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'green', 19, lastX, 1, 22));
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'blue', 19, lastX, targetX - lastX, 1));
        }
      } else {
        if (directionY === 1) {
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'green', 0, lastX, 1, 8));
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'blue', 8, targetX - 10, lastX - targetX + 11, 1));
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'green', 8, targetX - 10, 1, 11));
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'red', 19, targetX - 10, 10, 1));
        } else {
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'green', 32, lastX, 1, 8));
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'blue', 32, targetX - 10, lastX - targetX + 11, 1));
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'green', 19, targetX - 10, 1, 13));
          endCell.timelineCell.appendChild(newSegment(vp, e.classId, 'red', 19, targetX - 10, 10, 1));
        }
      }
    }

  }

}

