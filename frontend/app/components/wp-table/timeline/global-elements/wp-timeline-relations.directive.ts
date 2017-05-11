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
import {
  timelineElementCssClass,
  TimelineViewParameters,
} from "../wp-timeline";
import {WorkPackageTimelineTableController} from "../container/wp-timeline-container.directive";

import {Observable} from 'rxjs';
import * as moment from 'moment';
import Moment = moment.Moment;
import {openprojectModule} from "../../../../angular-modules";
import {States} from "../../../states.service";
import {WorkPackageStates} from "../../../work-package-states.service";
import {
  RelationsStateValue,
  WorkPackageRelationsService
} from "../../../wp-relations/wp-relations.service";
import {scopeDestroyed$} from "../../../../helpers/angular-rx-utils";
import {TimelineRelationElement} from "./timeline-relation-element";
import {RelationResource} from "../../../api/api-v3/hal-resources/relation-resource.service";

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
  segment.style.top = top + 'px';
  segment.style.left = left + 'px';
  segment.style.width = width + 'px';
  segment.style.height = height + 'px';
  return segment;
}

export class WorkPackageTableTimelineRelations {

  public wpTimeline:WorkPackageTimelineTableController;

  private container:ng.IAugmentedJQuery;

  private workPackageIdOrder:string[] = [];

  private elements:TimelineRelationElement[] = [];

  constructor(public $element:ng.IAugmentedJQuery,
              public $scope:ng.IScope,
              public states:States,
              public wpStates:WorkPackageStates,
              public wpRelations:WorkPackageRelationsService) {
  }

  $onInit() {
    this.container = this.$element.find('.wp-table-timeline--relations');
    this.wpTimeline.onRefreshRequested('relations', (vp:TimelineViewParameters) => this.refreshView(vp));

    this.requireVisibleRelations();
    this.setupRelationSubscription();
  }

  private refreshView(vp:TimelineViewParameters) {
    this.update(vp);
  }

  /**
   * Ensure visible relations (through table.rows) are loaded automatically.
   */
  private requireVisibleRelations() {

    // Observe the rows and request relations if changed
    // AND timeline is visible.
    Observable.combineLatest(
      this.states.table.timelineVisible.values$().takeUntil(scopeDestroyed$(this.$scope)),
      this.states.table.rendered.values$().takeUntil(scopeDestroyed$(this.$scope))
    )
      .filter(([timelineState, rendered]) => timelineState.isVisible)
      .subscribe(() => {
        this.workPackageIdOrder = this.getVisibleWorkPackageOrder();
        this.wpRelations.requireInvolved(this.workPackageIdOrder);
      });
  }

  private getVisibleWorkPackageOrder():string[] {
    const ids:string[] = [];

    jQuery('.wp-table--row').each((i, el) => {
      ids.push(el.getAttribute('data-work-package-id')!);
    });

    return ids;
  }

  /**
   * Refresh relations of visible rows.
   */
  private setupRelationSubscription() {
    this.wpStates.relations.observeChange()
      .takeUntil(scopeDestroyed$(this.$scope))
      .withLatestFrom(
        this.states.table.timelineVisible.values$().takeUntil(scopeDestroyed$(this.$scope)))
      .filter(([relations, timelineVisible]) => relations && timelineVisible.isVisible)
      .map(([relations]) => relations)
      .subscribe((nextVal) => {
        const [workPackageId, relations] = nextVal;

        if (workPackageId && this.wpTimeline.cells[workPackageId]) {
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

      this.renderElement(this.wpTimeline.viewParameters, elem);
    });
  }

  private update(vp:TimelineViewParameters) {
    this.removeAllVisibleElements();
    this.renderElements(vp);
  }

  private removeAllVisibleElements() {
    jQuery('.' + timelineGlobalElementCssClassname).remove();
  }

  private renderElements(vp:TimelineViewParameters) {
    for (const e of this.elements) {
      this.renderElement(vp, e);
    }
  }

  private renderElement(vp:TimelineViewParameters, e:TimelineRelationElement) {
    const involved = e.relation.ids;
    const idxFrom = this.workPackageIdOrder.indexOf(involved.from);
    const idxTo = this.workPackageIdOrder.indexOf(involved.to);

    const startCell = this.wpTimeline.cells[involved.from];
    const endCell = this.wpTimeline.cells[involved.to];

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
      const cell = this.wpTimeline.cells[id];
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

openprojectModule.component("wpTimelineRelations", {
  template: '<div class="wp-table-timeline--relations"></div>',
  controller: WorkPackageTableTimelineRelations,
  require: {
    wpTimeline: '^wpTimelineContainer'
  }
});
