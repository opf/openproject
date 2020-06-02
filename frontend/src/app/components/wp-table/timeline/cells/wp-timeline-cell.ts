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
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {States} from '../../../states.service';
import {WorkPackageCacheService} from '../../../work-packages/work-package-cache.service';
import {WorkPackageTimelineTableController} from '../container/wp-timeline-container.directive';
import {RenderInfo} from '../wp-timeline';
import {TimelineCellRenderer} from './timeline-cell-renderer';
import {TimelineMilestoneCellRenderer} from './timeline-milestone-cell-renderer';
import {registerWorkPackageMouseHandler} from './wp-timeline-cell-mouse-handler';
import {Injector} from '@angular/core';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export const classNameLeftLabel = 'labelLeft';
export const classNameRightContainer = 'containerRight';
export const classNameRightLabel = 'labelRight';
export const classNameLeftHoverLabel = 'labelHoverLeft';
export const classNameRightHoverLabel = 'labelHoverRight';
export const classNameHoverStyle = '-label-style';
export const classNameFarRightLabel = 'labelFarRight';
export const classNameShowOnHover = 'show-on-hover';
export const classNameHideOnHover = 'hide-on-hover';

export class WorkPackageCellLabels {

  constructor(public readonly center:HTMLDivElement|null,
              public readonly left:HTMLDivElement,
              public readonly leftHover:HTMLDivElement|null,
              public readonly right:HTMLDivElement,
              public readonly rightHover:HTMLDivElement|null,
              public readonly farRight:HTMLDivElement) {
  }

}

export class WorkPackageTimelineCell {
  @InjectField() wpCacheService:WorkPackageCacheService;
  @InjectField() halEditing:HalResourceEditingService;
  @InjectField() halEvents:HalEventsService;
  @InjectField() notificationService:WorkPackageNotificationService;
  @InjectField() states:States;
  @InjectField() loadingIndicator:LoadingIndicatorService;

  private wpElement:HTMLDivElement|null = null;

  private elementShape:string;

  private timelineCell:JQuery;
  private labels:WorkPackageCellLabels;

  constructor(public readonly injector:Injector,
              public workPackageTimeline:WorkPackageTimelineTableController,
              public renderers:{ milestone:TimelineMilestoneCellRenderer, generic:TimelineCellRenderer },
              public latestRenderInfo:RenderInfo,
              public classIdentifier:string,
              public workPackageId:string) {
  }

  getMarginLeftOfLeftSide():number {
    const renderer = this.cellRenderer(this.latestRenderInfo.workPackage);
    return renderer.getMarginLeftOfLeftSide(this.latestRenderInfo);
  }

  getMarginLeftOfRightSide():number {
    const renderer = this.cellRenderer(this.latestRenderInfo.workPackage);
    return renderer.getMarginLeftOfRightSide(this.latestRenderInfo);
  }

  getPaddingLeftForIncomingRelationLines():number {
    const renderer = this.cellRenderer(this.latestRenderInfo.workPackage);
    return renderer.getPaddingLeftForIncomingRelationLines(this.latestRenderInfo);
  }

  getPaddingRightForOutgoingRelationLines():number {
    const renderer = this.cellRenderer(this.latestRenderInfo.workPackage);
    return renderer.getPaddingRightForOutgoingRelationLines(this.latestRenderInfo);
  }

  canConnectRelations():boolean {
    const wp = this.latestRenderInfo.workPackage;
    if (wp.isMilestone) {
      return !_.isNil(wp.date);
    }

    return !_.isNil(wp.startDate) || !_.isNil(wp.dueDate);
  }

  public clear() {
    this.cellElement.html('');
    this.wpElement = null;
  }

  private get cellContainer() {
    return this.workPackageTimeline.timelineBody;
  }

  private get cellElement():JQuery {
    return this.cellContainer.find(`.${this.classIdentifier}`);
  }

  private lazyInit(renderer:TimelineCellRenderer, renderInfo:RenderInfo):Promise<void> {
    const body = this.workPackageTimeline.timelineBody[0];
    const cell = this.cellElement;

    if (!cell.length) {
      return Promise.reject('uninitialized');
    }

    const wasRendered = this.wpElement !== null && body.contains(this.wpElement);

    // If already rendered with correct shape, ignore
    if (wasRendered && (this.elementShape === renderer.type)) {
      return Promise.resolve();
    }

    // Remove the element first if we're redrawing
    this.clear();

    // Render the given element
    this.wpElement = renderer.render(renderInfo);
    this.labels = renderer.createAndAddLabels(renderInfo, this.wpElement);
    this.elementShape = renderer.type;

    // Register the element
    cell.append(this.wpElement);

    // Allow editing if editable
    if (renderer.canMoveDates(renderInfo.workPackage)) {
      this.wpElement.classList.add('-editable');

      registerWorkPackageMouseHandler(
        this.injector,
        () => this.latestRenderInfo,
        this.workPackageTimeline,
        this.wpCacheService,
        this.halEditing,
        this.halEvents,
        this.notificationService,
        this.loadingIndicator,
        cell[0],
        this.wpElement,
        this.labels,
        renderer,
        renderInfo);
    }

    return Promise.resolve();
  }

  private cellRenderer(workPackage:WorkPackageResource):TimelineCellRenderer {
    if (workPackage.isMilestone) {
      return this.renderers.milestone;
    }

    return this.renderers.generic;
  }

  public refreshView(renderInfo:RenderInfo) {
    this.latestRenderInfo = renderInfo;
    const renderer = this.cellRenderer(renderInfo.workPackage);

    // Render initial element if necessary
    this.lazyInit(renderer, renderInfo)
      .then(() => {
        // Render the upgrade from renderInfo
        const shouldBeDisplayed = renderer.update(
          this.wpElement as HTMLDivElement,
          this.labels,
          renderInfo);

        if (!shouldBeDisplayed) {
          this.clear();
        }
      })
      .catch(() => null);
  }

}
