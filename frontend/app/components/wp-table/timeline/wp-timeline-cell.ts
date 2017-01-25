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
import {Subscription} from "rxjs";
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import IScope = angular.IScope;
import Moment = moment.Moment;

const renderers = {
  milestone: new TimelineMilestoneCellRenderer(),
  generic: new TimelineCellRenderer()
};

export class WorkPackageTimelineCell {

  private subscription: Subscription;

  private latestRenderInfo: RenderInfo;

  private wpElement: HTMLDivElement = null;

  private elementShape: string = null;

  constructor(private workPackageTimeline: WorkPackageTimelineTableController,
              private wpCacheService: WorkPackageCacheService,
              private scope: IScope,
              private states: States,
              private workPackageId: string,
              private timelineCell: HTMLElement) {
  }

  activate() {
    this.subscription = this.workPackageTimeline.addWorkPackage(this.workPackageId)
      .subscribe(renderInfo => {
        this.updateView(renderInfo);
      });
  }

  deactivate() {
    this.clear();
    this.subscription && this.subscription.unsubscribe();
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
    registerWorkPackageMouseHandler(
      () => this.latestRenderInfo,
      this.workPackageTimeline,
      this.wpCacheService,
      this.timelineCell,
      this.wpElement,
      renderer,
      renderInfo);

    //-------------------------------------------------
    // TODO Naive horizontal scroll logic, for testing purpose only
    jQuery(this.timelineCell).on("wheel", ev => {
      const mwe = ev.originalEvent as MouseWheelEvent;

      // horizontal scroll
      // if (Math.abs(mwe.deltaY) < 20) {
      mwe.preventDefault();
      const scrollInDays = -Math.round(mwe.deltaX / 15);
      this.workPackageTimeline.wpTimelineHeader.addScrollDelta(scrollInDays);
      // }

      // forward vertical scroll
      const s = jQuery(".generic-table--results-container");
      window.requestAnimationFrame(() => {
        s.scrollTop(s.scrollTop() + mwe.deltaY);
        // s.stop().animate({scrollTop: s.scrollTop() + mwe.deltaY}, 200);
      });
    });
    //-------------------------------------------------
  }

  private cellRenderer(workPackage): TimelineCellRenderer {
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
    const shouldBeDisplayed = renderer.update(this.timelineCell, this.wpElement, renderInfo);
    if (!shouldBeDisplayed) {
      this.clear();
    }
  }
}
