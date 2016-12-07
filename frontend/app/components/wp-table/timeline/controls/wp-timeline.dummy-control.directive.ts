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

import {openprojectModule} from "../../../../angular-modules";
import {WorkPackageTimelineTableController} from '../wp-timeline-container.directive';
import {ZoomLevel, sortedZoomLevels} from '../wp-timeline';
import IDirective = angular.IDirective;
import IScope = angular.IScope;

class WorkPackageTimelineControlController {

  private wpTimeline: WorkPackageTimelineTableController;

  hscroll: number;
  currentZoom: number;
  localizedZoomLevels:{[idx: number]: string} = {};

  minZoomLevel = ZoomLevel.DAYS;
  maxZoomLevel = ZoomLevel.YEARS;

  text:any;

  static $inject = ['I18n'];

  constructor(private I18n:op.I18n) {
    this.text = {
      zoomLabel: I18n.t('js.timelines.zoom.slider'),
      zoomIn: I18n.t('js.timelines.zoom.in'),
      zoomOut: I18n.t('js.timelines.zoom.out'),
    }
  }

  $onInit() {
    this.hscroll = this.wpTimeline.viewParameterSettings.scrollOffsetInDays;
    this.localizedZoomLevels = {};

    sortedZoomLevels.forEach((value) => {
      let valueString = ZoomLevel[value];
      this.localizedZoomLevels[value] = this.I18n.t('js.timelines.zoom.' + valueString.toLowerCase());
    })

    this.currentZoom = ZoomLevel.DAYS;
  }

  get zoomLevels():number[] {
    return sortedZoomLevels;
  }

  updateScroll() {
    this.wpTimeline.viewParameterSettings.scrollOffsetInDays = this.hscroll;
    this.wpTimeline.refreshScrollOnly();
  }

  updateZoom(delta?:number) {

    if (delta !== undefined) {
      this.currentZoom += delta;
    }

    this.wpTimeline.viewParameterSettings.zoomLevel = this.currentZoom;
    this.wpTimeline.refreshView();
  }

}


openprojectModule.component("timelineControl", {
  templateUrl: '/components/wp-table/timeline/controls/wp-timeline.dummy-controls.directive.html',
  controller: WorkPackageTimelineControlController,
  require: {
    wpTimeline: '^wpTimelineContainer'
  }
});

