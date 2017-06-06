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

import * as moment from "moment";
import {State} from "reactivestates";
import {Observable} from "rxjs";
import {openprojectModule} from "../../../../angular-modules";
import {scopeDestroyed$} from "../../../../helpers/angular-rx-utils";
import {debugLog} from "../../../../helpers/debug_output";
import {RelationResource} from "../../../api/api-v3/hal-resources/relation-resource.service";
import {States} from "../../../states.service";
import {WorkPackageStates} from "../../../work-package-states.service";
import {RenderedRow} from "../../../wp-fast-table/builders/primary-render-pass";
import {WorkPackageTableTimelineService} from "../../../wp-fast-table/state/wp-table-timeline.service";
import {RelationsStateValue, WorkPackageRelationsService} from "../../../wp-relations/wp-relations.service";
import {WorkPackageTimelineTableController} from "../container/wp-timeline-container.directive";
import {timelineElementCssClass, TimelineViewParameters} from "../wp-timeline";
import {TimelineRelationElement} from "./timeline-relation-element";
import Moment = moment.Moment;

const DEBUG_DRAW_RELATION_LINES_WITH_COLOR = false;

export const timelineGlobalElementCssClassname = 'relation-line';

function newSegment(vp:TimelineViewParameters,
                    classNames:string[],
                    yPosition: number,
                    top:number,
                    left:number,
                    width:number,
                    height: number,
                    color?: string): HTMLElement {

  const segment = document.createElement('div');
  segment.classList.add(
    timelineElementCssClass,
    timelineGlobalElementCssClassname,
    ...classNames
  );

  // segment.style.backgroundColor = color;
  segment.style.top = ((yPosition * 41) + top) + "px";
  segment.style.left = left + 'px';
  segment.style.width = width + 'px';
  segment.style.height = height + 'px';
  if (DEBUG_DRAW_RELATION_LINES_WITH_COLOR && color !== undefined) {
    segment.style.backgroundColor = color;
  }
  return segment;
}

export class WorkPackageTableTimelineRelations {

  public wpTimeline:WorkPackageTimelineTableController;

  private container:JQuery;

  private relationsRequestedFor:string[] = [];

  private elements:TimelineRelationElement[] = [];

  constructor(public $element:ng.IAugmentedJQuery,
              public $scope:ng.IScope,
              public states:States,
              public wpStates:WorkPackageStates,
              public wpTableTimeline:WorkPackageTableTimelineService,
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
    Observable.combineLatest(
      this.states.table.timelineVisible.values$(),
      this.states.table.rendered.values$()
    )
      .takeUntil(scopeDestroyed$(this.$scope))
      .filter(([timelineState, result]) => timelineState.isVisible && result.renderedOrder.length > 0)
      .subscribe(() => {
        // remove all elements. They are refreshed either after initial loading
        this.removeAllVisibleElements();
        this.refreshRelationsWhenNeeded();
      });
  }

  private get workPackageIdOrder() {
    return this.wpTimeline.workPackageIdOrder;
  }

  private refreshRelationsWhenNeeded():void {
    const requiredForRelations:string[] = [];

    _.each(this.workPackageIdOrder, (el:RenderedRow) => {
      if (el.isWorkPackage && el.belongsTo) {
        requiredForRelations.push(el.belongsTo.id.toString());
      }
    });

    if (_.isEqual(requiredForRelations, this.relationsRequestedFor)) {
      debugLog('WP order unchanged, not requesting new relations, only updating them.');
      this.renderElements(this.wpTimeline.viewParameters);
      return;
    }

    this.relationsRequestedFor = requiredForRelations;
    this.wpRelations.requireInvolved(requiredForRelations);
  }

  /**
   * Refresh relations of visible rows.
   */
  private setupRelationSubscription() {
    // Refresh drawn work package order
    Observable.combineLatest(
      this.wpStates.relations.observeChange(),
      this.states.table.rendered.values$())
      .withLatestFrom(this.states.table.timelineVisible.values$())
      .takeUntil(scopeDestroyed$(this.$scope))
      .filter(([[relations, rendered], timelineVisible]) => relations && timelineVisible.isVisible)
      .map(([[relationStateValue, rendered], timelineVisible]) => relationStateValue)
      .filter(([workPackageId, relations]) => !!(relations && workPackageId && this.wpTimeline.workPackageInView(workPackageId)))
      .subscribe(([workPackageId, relations]) => {
        this.removeRelationElementsForWorkPackage(workPackageId);
        this.refreshRelations(relations!);
      });

    this.states.workPackages.observeChange()
      .withLatestFrom(this.states.table.timelineVisible.values$())
      .takeUntil(scopeDestroyed$(this.$scope))
      .filter(([, timelineVisible]) => timelineVisible.visible)
      .map(([[workPackageId], timelineVisible]) => [workPackageId, this.wpStates.relations.get(workPackageId)] as [string, State<RelationsStateValue>])
      .filter(([workPackageId, state]) => state !== undefined)
      .subscribe(([workPackageId, state]) => {
        this.removeRelationElementsForWorkPackage(workPackageId);
        this.refreshRelations(state.value!);
    });
  }

  private refreshRelations(relations: RelationsStateValue) {
    const relevant = _.pickBy(relations, (relation: RelationResource) => {
      return relation.type === "precedes" || relation.type === "follows";
    });

    _.each(relevant, (relation:RelationResource) => {
      this.removeRelationElementsForWorkPackage(relation.ids.from);
      const elem = new TimelineRelationElement(relation.ids.from, relation);
      this.elements.push(elem);

      this.renderElement(this.wpTimeline.viewParameters, elem);
    });
  }

  private update(vp:TimelineViewParameters) {
    this.removeAllVisibleElements();
    this.renderElements(vp);
  }

  private removeRelationElementsForWorkPackage(workPackageId: string) {
    const prefix = TimelineRelationElement.workPackagePrefix(workPackageId);
    this.container.find(`.${prefix}`).remove();
    _.remove(this.elements, (element) => element.belongsToId === workPackageId);
  }

  private removeAllVisibleElements() {
    this.container.find('.' + timelineGlobalElementCssClassname).remove();
  }

  private renderElements(vp:TimelineViewParameters) {
    for (const e of this.elements) {
      this.renderElement(vp, e);
    }
  }

  private renderElement(vp:TimelineViewParameters, e:TimelineRelationElement) {
    const involved = e.relation.ids;

    // Get the rendered rows
    const idxFrom = _.findIndex(this.workPackageIdOrder, (el:RenderedRow) => el.isWorkPackage && el.belongsTo!.id.toString() === involved.from);
    const idxTo = _.findIndex(this.workPackageIdOrder, (el:RenderedRow) => el.isWorkPackage && el.belongsTo!.id.toString() === involved.to);

    const startCell = this.wpTimeline.workPackageCell(involved.from);
    const endCell = this.wpTimeline.workPackageCell(involved.to);

    // If targets do not exist anywhere in the table, skip
    if (idxFrom === -1 || idxTo === -1 || _.isNil(startCell) || _.isNil(endCell)) {
      return;
    }

    // If any of the targets are hidden in the table, skip
    if (this.workPackageIdOrder[idxFrom].hidden || this.workPackageIdOrder[idxTo].hidden) {
      return;
    }

    // Skip if relations cannot be drawn between these cells
    if (!startCell.canConnectRelations() || !endCell.canConnectRelations()) {
      return;
    }

    // Get X values
    let lastX = startCell.getRightmostXValue();
    const targetX = endCell.getLeftmostXValue() + endCell.getInnerXOffsetForRelationLineDock();
    const hookLength = endCell.getInnerXOffsetForRelationLineDock();

    // Vertical direction
    const directionY: "toUp" | "toDown" = idxFrom < idxTo ? "toDown" : "toUp";

    // Horizontal direction
    const directionX: "toLeft" | "beneath" | "toRight" =
      targetX > lastX ? "toRight" : targetX < lastX ? "toLeft" : "beneath";

    // start
    if (!startCell) {
      return;
    }

    // Draw the first line next to the bar/milestone element
    this.container.append(newSegment(vp, e.classNames, idxFrom, 19, lastX, hookLength, 1, "red"));
    lastX += hookLength;

    // Draw vertical line between rows
    const height = Math.abs(idxTo - idxFrom);
    if (directionY === "toDown") {
      if (directionX === "toRight" || directionX === "beneath") {
        this.container.append(newSegment(vp, e.classNames, idxFrom, 19, lastX, 1, height * 41, "black"));
      } else if (directionX === "toLeft") {
        this.container.append(newSegment(vp, e.classNames, idxFrom, 19, lastX, 1, (height * 41) - 10, "black"));
      }
    } else if (directionY === "toUp") {
      this.container.append(newSegment(vp, e.classNames, idxTo, 30, lastX, 1, (height * 41) - 10, "black"));
    }

    // Draw end corner to the target
    if (directionX === "toRight") {
      if (directionY === "toDown") {
        this.container.append(newSegment(vp, e.classNames, idxTo, 19, lastX, targetX - lastX, 1, "red"));
      } else if (directionY === "toUp") {
        this.container.append(newSegment(vp, e.classNames, idxTo, 20, lastX, 1, 10, "green"));
        this.container.append(newSegment(vp, e.classNames, idxTo, 20, lastX, targetX - lastX, 1, "lightsalmon"));
      }
    } else if (directionX === "toLeft") {
      if (directionY === "toDown") {
        this.container.append(newSegment(vp, e.classNames, idxTo, 0, lastX, 1, 8, "red"));
        this.container.append(newSegment(vp, e.classNames, idxTo, 8, targetX, lastX - targetX, 1, "green"));
        this.container.append(newSegment(vp, e.classNames, idxTo, 8, targetX, 1, 11, "blue"));
      } else if (directionY === "toUp") {
        this.container.append(newSegment(vp, e.classNames, idxTo, 30, targetX + 1, lastX - targetX, 1, "red"));
        this.container.append(newSegment(vp, e.classNames, idxTo, 19, targetX + 1, 1, 11, "blue"));
      }
    }
  }

}

openprojectModule.component('wpTimelineRelations', {
  template: '<div class="wp-table-timeline--relations"></div>',
  controller: WorkPackageTableTimelineRelations,
  require: {
    wpTimeline: '^wpTimelineContainer'
  }
});
