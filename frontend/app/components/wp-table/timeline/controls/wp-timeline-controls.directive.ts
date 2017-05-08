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

import { openprojectModule } from "../../../../angular-modules";
import { WorkPackageTableTimelineService } from './../../../wp-fast-table/state/wp-table-timeline.service';
import { ZoomLevel } from '../wp-timeline';
import IDirective = angular.IDirective;
import IScope = angular.IScope;
import {WorkPackageTimelineTableController} from "../container/wp-timeline-container.directive";

class WorkPackageTimelineControlController {

  public timelineVisible: boolean = false;
  private wpTimeline: WorkPackageTimelineTableController;

  hscroll: number;
  currentZoom: number;

  minZoomLevel = ZoomLevel.DAYS;
  maxZoomLevel = ZoomLevel.YEARS;

  text: any;

  constructor(public wpTableTimeline: WorkPackageTableTimelineService,
              public $scope: ng.IScope,
              public I18n: op.I18n) {
    'ngInject';

    this.text = {
      zoomIn: I18n.t('js.timelines.zoom.in'),
      zoomOut: I18n.t('js.timelines.zoom.out'),
    };

    wpTableTimeline.observeOnScope($scope).subscribe(() => {
      this.timelineVisible = wpTableTimeline.isVisible;
    });
  }

  $onInit() {
    this.hscroll = this.wpTimeline.viewParameterSettings.scrollOffsetInDays;
    this.currentZoom = ZoomLevel.DAYS;
  }

  updateScroll() {
    this.wpTimeline.viewParameterSettings.scrollOffsetInDays = this.hscroll;
    this.wpTimeline.refreshScrollOnly();
  }

  updateZoom(delta: number) {
    this.currentZoom += delta;

    this.wpTimeline.viewParameterSettings.zoomLevel = this.currentZoom;
    this.wpTimeline.refreshView();
  }

}


openprojectModule.component("wpTimelineControls", {
  templateUrl: '/components/wp-table/timeline/controls/wp-timeline-controls.directive.html',
  controller: WorkPackageTimelineControlController,
  require: {
    wpTimeline: '^wpTimelineContainer'
  }
});

