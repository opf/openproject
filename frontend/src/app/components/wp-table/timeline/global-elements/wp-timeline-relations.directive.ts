// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Component, ElementRef, Injector, OnInit} from '@angular/core';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {State} from 'reactivestates';
import {combineLatest} from 'rxjs';
import {filter, map, take} from 'rxjs/operators';
import {States} from '../../../states.service';
import {RelationsStateValue, WorkPackageRelationsService} from '../../../wp-relations/wp-relations.service';
import {WorkPackageTimelineCell} from '../cells/wp-timeline-cell';
import {WorkPackageTimelineTableController} from '../container/wp-timeline-container.directive';
import {timelineElementCssClass, TimelineViewParameters} from '../wp-timeline';
import {TimelineRelationElement, workPackagePrefix} from './timeline-relation-element';
import {WorkPackageViewTimelineService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

const DEBUG_DRAW_RELATION_LINES_WITH_COLOR = false;

export const timelineGlobalElementCssClassname = 'relation-line';

function newSegment(vp:TimelineViewParameters,
                    classNames:string[],
                    yPosition:number,
                    top:number,
                    left:number,
                    width:number,
                    height:number,
                    color?:string):HTMLElement {

  const segment = document.createElement('div');
  segment.classList.add(
    timelineElementCssClass,
    timelineGlobalElementCssClassname,
    ...classNames
  );

  // segment.style.backgroundColor = color;
  segment.style.top = ((yPosition * 40) + top) + 'px';
  segment.style.left = left + 'px';
  segment.style.width = width + 'px';
  segment.style.height = height + 'px';

  if (DEBUG_DRAW_RELATION_LINES_WITH_COLOR && color !== undefined) {
    segment.style.zIndex = '9999999';
    segment.style.backgroundColor = color;
  }
  return segment;
}

@Component({
  selector: 'wp-timeline-relations',
  template: '<div class="wp-table-timeline--relations"></div>'
})
export class WorkPackageTableTimelineRelations extends UntilDestroyedMixin implements OnInit {

  @InjectField() querySpace:IsolatedQuerySpace;

  private container:JQuery;

  private workPackagesWithRelations:{ [workPackageId:string]:State<RelationsStateValue> } = {};

  constructor(public readonly injector:Injector,
              public elementRef:ElementRef,
              public states:States,
              public workPackageTimelineTableController:WorkPackageTimelineTableController,
              public wpTableTimeline:WorkPackageViewTimelineService,
              public wpRelations:WorkPackageRelationsService) {
    super();
  }

  ngOnInit() {
    const $element = jQuery(this.elementRef.nativeElement);
    this.container = $element.find('.wp-table-timeline--relations');
    this.workPackageTimelineTableController
      .onRefreshRequested('relations', (vp:TimelineViewParameters) => this.refreshView());

    this.setupRelationSubscription();
  }

  private refreshView() {
    this.update();
  }

  private get workPackageIdOrder() {
    return this.workPackageTimelineTableController.workPackageIdOrder;
  }

  /**
   * Refresh relations of visible rows.
   */
  private setupRelationSubscription() {
    // for all visible WorkPackage rows...
    combineLatest([
      this.querySpace.renderedWorkPackages.values$(),
      this.wpTableTimeline.live$()
    ])
      .pipe(
        filter(([_, timeline]) => timeline.visible),
        this.untilDestroyed(),
        map(([rendered, _]) => rendered)
      )
      .subscribe(list => {
        // ... make sure that the corresponding relations are loaded ...
        const wps = _.compact(list.map(row => row.workPackageId) as string[]);
        this.wpRelations.requireAll(wps);

        wps.forEach(wpId => {
          const relationsForWorkPackage = this.wpRelations.state(wpId);
          this.workPackagesWithRelations[wpId] = relationsForWorkPackage;

          // ... once they are loaded, display them.
          relationsForWorkPackage.values$()
            .pipe(
              take(1)
            )
            .subscribe(() => {
              this.renderWorkPackagesRelations([wpId]);
            });
        });
      });

    // When a WorkPackage changes, redraw the corresponding relations
    this.states.workPackages.observeChange()
      .pipe(
        this.untilDestroyed(),
        filter(() => this.wpTableTimeline.isVisible)
      )
      .subscribe(([workPackageId]) => {
        this.renderWorkPackagesRelations([workPackageId]);
      });

  }

  private renderWorkPackagesRelations(workPackageIds:string[]) {
    workPackageIds.forEach(workPackageId => {
      const workPackageWithRelation = this.workPackagesWithRelations[workPackageId];
      if (_.isNil(workPackageWithRelation)) {
        return;
      }

      this.removeRelationElementsForWorkPackage(workPackageId);
      const relations = _.values(workPackageWithRelation.value!);
      const relationsList = _.values(relations);
      relationsList.forEach(relation => {

        if (!(relation.type === 'precedes'
          || relation.type === 'follows')) {
          return;
        }

        const elem = new TimelineRelationElement(relation.ids.from, relation);
        this.renderElement(this.workPackageTimelineTableController.viewParameters, elem);
      });

    });
  }

  private update() {
    this.removeAllVisibleElements();
    this.renderElements();
  }

  private removeRelationElementsForWorkPackage(workPackageId:string) {
    const className = workPackagePrefix(workPackageId);
    const found = this.container.find('.' + className);
    found.remove();
  }

  private removeAllVisibleElements() {
    this.container.find('.' + timelineGlobalElementCssClassname).remove();
  }

  private renderElements() {
    const wpIdsWithRelations:string[] = _.keys(this.workPackagesWithRelations);
    this.renderWorkPackagesRelations(wpIdsWithRelations);

  }

  /**
   * Render a single relation to all shown work packages. Since work packages may occur multiple
   * times in the timeline, iterate all potential combinations and render them.
   * @param vp
   * @param e
   */
  private renderElement(vp:TimelineViewParameters, e:TimelineRelationElement) {
    const involved = e.relation.ids;

    const startCells = this.workPackageTimelineTableController.workPackageCells(involved.to);
    const endCells = this.workPackageTimelineTableController.workPackageCells(involved.from);

    // If either sources or targets are not rendered, ignore this relation
    if (startCells.length === 0 || endCells.length === 0) {
      return;
    }

    // Now, render all sources to all targets
    startCells.forEach((startCell) => {
      const idxFrom = this.workPackageTimelineTableController.workPackageIndex(startCell.classIdentifier);
      endCells.forEach((endCell) => {
        const idxTo = this.workPackageTimelineTableController.workPackageIndex(endCell.classIdentifier);
        this.renderRelation(vp, e, idxFrom, idxTo, startCell, endCell);
      });
    });
  }

  private renderRelation(vp:TimelineViewParameters,
                         e:TimelineRelationElement,
                         idxFrom:number,
                         idxTo:number,
                         startCell:WorkPackageTimelineCell,
                         endCell:WorkPackageTimelineCell) {

    const rowFrom = this.workPackageIdOrder[idxFrom];
    const rowTo = this.workPackageIdOrder[idxTo];

    // If any of the targets are hidden in the table, skip
    if (!(rowFrom && rowTo) || (rowFrom.hidden || rowTo.hidden)) {
      return;
    }

    // Skip if relations cannot be drawn between these cells
    if (!startCell.canConnectRelations() || !endCell.canConnectRelations()) {
      return;
    }

    // Get X values
    // const hookLength = endCell.getPaddingLeftForIncomingRelationLines();
    const startX = startCell.getMarginLeftOfRightSide() - startCell.getPaddingRightForOutgoingRelationLines();
    const targetX = endCell.getMarginLeftOfLeftSide() + endCell.getPaddingLeftForIncomingRelationLines();

    // Vertical direction
    const directionY:'toUp'|'toDown' = idxFrom < idxTo ? 'toDown' : 'toUp';

    // Horizontal direction
    const directionX:'toLeft'|'beneath'|'toRight' =
      targetX > startX ? 'toRight' : targetX < startX ? 'toLeft' : 'beneath';

    // start
    if (!startCell) {
      return;
    }

    // Draw the first line next to the bar/milestone element
    const paddingRight = startCell.getPaddingRightForOutgoingRelationLines();
    const startLineWith = endCell.getPaddingLeftForIncomingRelationLines()
      + (paddingRight > 0 ? paddingRight : 0);
    this.container.append(newSegment(vp, e.classNames, idxFrom, 19, startX, startLineWith, 1, 'red'));
    let lastX = startX + startLineWith;
    // lastX += hookLength;

    // Draw vertical line between rows
    const height = Math.abs(idxTo - idxFrom);
    if (directionY === 'toDown') {
      if (directionX === 'toRight' || directionX === 'beneath') {
        this.container.append(newSegment(vp, e.classNames, idxFrom, 19, lastX, 1, height * 40, 'black'));
      } else if (directionX === 'toLeft') {
        this.container.append(newSegment(vp, e.classNames, idxFrom, 19, lastX, 1, (height * 40) - 10, 'black'));
      }
    } else if (directionY === 'toUp') {
      this.container.append(newSegment(vp, e.classNames, idxTo, 30, lastX, 1, (height * 40) - 10, 'black'));
    }

    // Draw end corner to the target
    if (directionX === 'toRight') {
      if (directionY === 'toDown') {
        this.container.append(newSegment(vp, e.classNames, idxTo, 19, lastX, targetX - lastX, 1, 'red'));
      } else if (directionY === 'toUp') {
        this.container.append(newSegment(vp, e.classNames, idxTo, 20, lastX, 1, 10, 'green'));
        this.container.append(newSegment(vp, e.classNames, idxTo, 20, lastX, targetX - lastX, 1, 'lightsalmon'));
      }
    } else if (directionX === 'toLeft') {
      if (directionY === 'toDown') {
        this.container.append(newSegment(vp, e.classNames, idxTo, 0, lastX, 1, 8, 'red'));
        this.container.append(newSegment(vp, e.classNames, idxTo, 8, targetX, lastX - targetX, 1, 'green'));
        this.container.append(newSegment(vp, e.classNames, idxTo, 8, targetX, 1, 11, 'blue'));
      } else if (directionY === 'toUp') {
        this.container.append(newSegment(vp, e.classNames, idxTo, 30, targetX + 1, lastX - targetX, 1, 'red'));
        this.container.append(newSegment(vp, e.classNames, idxTo, 19, targetX + 1, 1, 11, 'blue'));
      }
    }

  }
}

