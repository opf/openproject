import { WorkPackageTableTimelineVisible } from './../../wp-fast-table/wp-table-timeline-visible';
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
import {States} from "../../states.service";
import {RenderInfo} from "./wp-timeline";
import {WorkPackageTimelineTableController} from "./wp-timeline-container.directive";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";
import {registerWorkPackageMouseHandler} from "./wp-timeline-cell-mouse-handler";
import {TimelineMilestoneCellRenderer} from "./cell-renderer/timeline-milestone-cell-renderer";
import {TimelineCellRenderer} from "./cell-renderer/timeline-cell-renderer";
import {Observable, Subscription} from "rxjs";
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import * as moment from "moment";
import { injectorBridge } from "../../angular/angular-injector-bridge.functions";
import IScope = angular.IScope;
import Moment = moment.Moment;
import {WorkPackageTableRefreshService} from "../wp-table-refresh-request.service";

const renderers = {
  milestone: new TimelineMilestoneCellRenderer(),
  generic: new TimelineCellRenderer()
};

export class WorkPackageTimelineCell {
  public wpCacheService: WorkPackageCacheService;
  public wpTableRefresh: WorkPackageTableRefreshService;
  public states: States;

  private subscription: Subscription;

  public latestRenderInfo: RenderInfo;

  private wpElement: HTMLDivElement|null = null;

  private elementShape: string;

  constructor(private workPackageTimeline: WorkPackageTimelineTableController,
              private workPackageId: string,
              public timelineCell: HTMLElement) {
    injectorBridge(this);
  }

  activate() {
    this.subscription = Observable.combineLatest(
      this.workPackageTimeline.addWorkPackage(this.workPackageId),
      this.states.table.timelineVisible.values$().takeUntil(this.states.table.stopAllSubscriptions)
    )
      .filter(([renderInfo, timelineState]) => timelineState.isVisible)
      .map(([renderInfo, _visible]) => renderInfo)
      .subscribe(renderInfo => {
        this.updateView(renderInfo);
        this.workPackageTimeline.globalService.updateWorkPackageInfo(this);
      });
  }

  deactivate() {
    this.clear();
    this.workPackageTimeline.globalService.removeWorkPackageInfo(this.workPackageId);
    this.subscription && this.subscription.unsubscribe();
  }

  getLeftmostPosition(): number {
    const renderer = this.cellRenderer(this.latestRenderInfo.workPackage);
    return renderer.getLeftmostPosition(this.latestRenderInfo);
  }

  getRightmostPosition(): number {
    const renderer = this.cellRenderer(this.latestRenderInfo.workPackage);
    return renderer.getRightmostPosition(this.latestRenderInfo);
  }

  canConnectRelations(): boolean {
    const wp = this.latestRenderInfo.workPackage;
    if (wp.isMilestone) {
      return !_.isNil(wp.date);
    }

    return !_.isNil(wp.startDate) || !_.isNil(wp.dueDate);
  }

  private clear() {
    this.timelineCell.innerHTML = "";
    this.wpElement = null;
  }

  private lazyInit(renderer: TimelineCellRenderer, renderInfo: RenderInfo) {
    const wasRendered = this.wpElement !== null && this.wpElement.parentNode;

    // If already rendered with correct shape, ignore
    if (wasRendered && (this.elementShape === renderer.type)) {
      return;
    }

    // Remove the element first if we're redrawing
    if (wasRendered) {
      this.clear();
    }

    // Render the given element
    this.wpElement = renderer.render(renderInfo);
    this.elementShape = renderer.type;

    // Register the element
    this.timelineCell.appendChild(this.wpElement);

    // Allow editing if editable
    if (renderInfo.workPackage.isEditable) {
      this.wpElement.classList.add('-editable');

      registerWorkPackageMouseHandler(
        () => this.latestRenderInfo,
        this.workPackageTimeline,
        this.wpCacheService,
        this.wpTableRefresh,
        this.timelineCell,
        this.wpElement,
        renderer,
        renderInfo);
    }
  }

  private cellRenderer(workPackage: WorkPackageResourceInterface): TimelineCellRenderer {
    if (workPackage.isMilestone) {
      return renderers.milestone;
    }

    return renderers.generic;
  }

  private updateView(renderInfo: RenderInfo) {
    this.latestRenderInfo = renderInfo;
    const renderer = this.cellRenderer(renderInfo.workPackage);

    // Render initial element if necessary
    this.lazyInit(renderer, renderInfo);

    // Render the upgrade from renderInfo
    const shouldBeDisplayed = renderer.update(this.timelineCell, this.wpElement as HTMLDivElement, renderInfo);
    if (!shouldBeDisplayed) {
      this.clear();
    }
  }

}

WorkPackageTimelineCell.$inject = ['wpCacheService', 'wpTableRefresh', 'states', 'TimezoneService'];
