
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
import {Observable} from "rxjs/Rx";
import {scopeDestroyed$} from "../../../helpers/angular-rx-utils";
import {debugLog} from "../../../helpers/debug_output";
import {injectorBridge} from "../../angular/angular-injector-bridge.functions";
import {RelationResource} from "../../api/api-v3/hal-resources/relation-resource.service";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {States} from "../../states.service";
import {WorkPackageStates} from "../../work-package-states.service";
import {RelationsStateValue, WorkPackageRelationsService} from "../../wp-relations/wp-relations.service";
import {TimelineRelationElement} from "./global-elements/timeline-relation-element";
import {timelineElementCssClass, TimelineViewParameters} from "./wp-timeline";
import {WorkPackageTimelineCell} from "./wp-timeline-cell";
import IScope = angular.IScope;


export const timelineGlobalElementCssClassname = "relation-line";

function newSegment(vp: TimelineViewParameters,
                    classNames: string[],
                    color: string,
                    top: number,
                    left: number,
                    width: number,
                    height: number): HTMLElement {

  const segment = document.createElement('div');
  segment.classList.add(
    timelineElementCssClass,
    timelineGlobalElementCssClassname,
    ...classNames
  );

  // segment.style.backgroundColor = color;
  segment.style.marginLeft = vp.scrollOffsetInPx + 'px';
  segment.style.top = top + 'px';
  segment.style.left = left + 'px';
  segment.style.width = width + 'px';
  segment.style.height = height + 'px';
  return segment;
}

export class WpTimelineGlobalService {

  // Injected arguments
  public states:States;
  public wpStates:WorkPackageStates;
  public wpRelations:WorkPackageRelationsService;

  private workPackageIdOrder:string[] = [];

  private viewParameters:TimelineViewParameters;

  private cells:{[id: string]:WorkPackageTimelineCell} = {};

  private elements:TimelineRelationElement[] = [];

  constructor(private scope:IScope) {
    injectorBridge(this);
    this.requireVisibleRelations();
    this.setupRelationSubscription();
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

  /**
   * Ensure visible relations (through table.rows) are loaded automatically.
   */
  private requireVisibleRelations() {

    // Observe the rows and request relations if changed
    // AND timeline is visible.
    Observable.combineLatest(
      this.states.table.timelineVisible.values$().takeUntil(scopeDestroyed$(this.scope)),
      this.states.table.rows.values$().takeUntil(scopeDestroyed$(this.scope))
    )
      .filter(([visible, rows]) => visible)
      .map(([visible, rows]) => rows)
      .subscribe((rows: WorkPackageResource[]) => {
        this.workPackageIdOrder = rows.map(wp => wp.id.toString());
        this.wpRelations.requireInvolved(this.workPackageIdOrder);
      });
  }

  /**
   * Refresh relations of visible rows.
   */
  private setupRelationSubscription() {
    const relations = this.wpStates.relations.observeChange();
    const tlVisible = this.states.table.timelineVisible.values$();

    relations
      .withLatestFrom(tlVisible)
      .takeUntil(scopeDestroyed$(this.scope))
      .filter(([relations, visible]) => relations && visible)
      .map(([relations, visible]) => relations)
      .subscribe((nextVal) => {
        const [workPackageId, relations] = nextVal;

        if (workPackageId && this.cells[workPackageId]) {
          this.refreshRelations(workPackageId, relations!);
        }
      });
  }

  private refreshRelations(workPackageId:string, relations:RelationsStateValue) {
    // Remove all previous relations for the work package
    const prefix = TimelineRelationElement.workPackagePrefix(workPackageId);
    jQuery(`.${prefix}`).remove();
    _.remove(this.elements, (element) => element.belongsToId === workPackageId);

    _.each(relations, (relation:RelationResource) => {
      const elem = new TimelineRelationElement(workPackageId, relation);
      this.elements.push(elem);

      if (this.viewParameters !== undefined) {
        this.renderElement(elem);
      }
    });
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

    for (const e of this.elements) {
      this.renderElement(e);
    }
  }

  private renderElement(e:TimelineRelationElement) {
    const vp = this.viewParameters;
    const involved = e.relation.ids;
    const idxFrom = this.workPackageIdOrder.indexOf(involved.from);
    const idxTo = this.workPackageIdOrder.indexOf(involved.to);

    const startCell = this.cells[involved.from];
    const endCell = this.cells[involved.to];

    if (idxFrom === -1 || idxTo === -1 || _.isNil(startCell) || _.isNil(endCell)) {
      return;
    }

    if (!startCell.canConnectRelations() || !endCell.canConnectRelations()) {
      return;
    }

    const directionY = idxFrom < idxTo ? 1 : -1;
    let lastX = startCell.getRightmostPosition();
    let targetX = endCell.getLeftmostPosition();
    const directionX = targetX >= lastX ? 1 : -1;

    // start
    if (!startCell) {
      return;
    }

    const startLength = 13;
    startCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'green', 19, lastX, startLength, 1));
    lastX += startLength;

    if (directionY === 1) {
      startCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'red', 19, lastX, 1, 22));
    } else {
      startCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'red', -1, lastX, 1, 21));
    }

    // vert segment
    for (let index = idxFrom + directionY; index !== idxTo; index += directionY) {
      const id = this.workPackageIdOrder[index];
      const cell = this.cells[id];
      if (_.isNil(cell)) {
        continue;
      }
      cell.timelineCell.appendChild(newSegment(vp, e.classNames, 'blue', 0, lastX, 1, 42));
    }

    // end
    if (directionX === 1) {
      if (directionY === 1) {
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'green', 0, lastX, 1, 19));
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'blue', 19, lastX, targetX - lastX, 1));
      } else {
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'green', 19, lastX, 1, 22));
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'blue', 19, lastX, targetX - lastX, 1));
      }
    } else {
      if (directionY === 1) {
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'green', 0, lastX, 1, 8));
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'blue', 8, targetX - 10, lastX - targetX + 11, 1));
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'green', 8, targetX - 10, 1, 11));
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'red', 19, targetX - 10, 10, 1));
      } else {
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'green', 32, lastX, 1, 8));
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'blue', 32, targetX - 10, lastX - targetX + 11, 1));
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'green', 19, targetX - 10, 1, 13));
        endCell.timelineCell.appendChild(newSegment(vp, e.classNames, 'red', 19, targetX - 10, 10, 1));
      }
    }
  }
}

WpTimelineGlobalService.$inject = ['states', 'wpStates', 'wpRelations'];
