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
import {timelineElementCssClass, RenderInfo, calculatePositionValueForDayCount} from "./wp-timeline";
import {WorkPackageTimelineTableController} from "./wp-timeline-container.directive";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";
import {registerWorkPackageMouseHandler} from "./wp-timeline-cell-mouse-handler";
import {TimelineMilestoneCellRenderer} from './cell-renderer/timeline-milestone-cell-renderer';
import {TimelineCellRenderer} from './cell-renderer/timeline-cell-renderer';
import IScope = angular.IScope;
import WorkPackage = op.WorkPackage;
import Observable = Rx.Observable;
import IDisposable = Rx.IDisposable;
import Moment = moment.Moment;

const renderers = {
  milestone: new TimelineMilestoneCellRenderer(),
  generic: new TimelineCellRenderer()
}

export class WorkPackageTimelineCell {

  private disposable: IDisposable;

  private element: HTMLDivElement = null;
  private elementShape: string = null;

  constructor(private workPackageTimeline: WorkPackageTimelineTableController,
              private wpCacheService: WorkPackageCacheService,
              private scope: IScope,
              private states: States,
              private workPackageId: string,
              private timelineCell: HTMLElement) {
  }

  activate() {
    this.disposable = this.workPackageTimeline.addWorkPackage(this.workPackageId)
      .subscribe(renderInfo => {
        this.updateView(renderInfo);
      });
  }

  // TODO never called so far
  deactivate() {
    this.timelineCell.innerHTML = "";
    this.disposable && this.disposable.dispose();
  }

  private lazyInit(renderer: TimelineCellRenderer, renderInfo: RenderInfo) {

    // If already rendered with correct shape, ignore
    if (this.element !== null && (this.elementShape === renderer.type)) {
      return;
    }

    // Remove the element first if we're redrawing
    if (this.element !== null) {
       this.element.parentNode.removeChild(this.element);
    }

    // Render the given element
    this.element = renderer.render(renderInfo);
    this.elementShape = renderer.type;

    // Register the element
    this.timelineCell.appendChild(this.element);
    registerWorkPackageMouseHandler(
      this.workPackageTimeline,
      this.wpCacheService,
      this.element,
      renderer,
      renderInfo)
  }

  private cellRenderer(workPackage):TimelineCellRenderer {
    if (workPackage.isMilestone) {
      return renderers.milestone;
    }

    return renderers.generic;
  }

  private updateView(renderInfo: RenderInfo) {
    const wp = renderInfo.workPackage;
    const renderer = this.cellRenderer(wp);

    // Render initial element if necessary
    this.lazyInit(renderer, renderInfo);

    // Render the upgrade from renderInfo
    renderer.update(this.element, wp, renderInfo);
  }
}
