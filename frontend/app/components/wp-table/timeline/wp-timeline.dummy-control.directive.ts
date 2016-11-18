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

import {openprojectModule} from "../../../angular-modules";
import {WorkPackageTimelineService} from "./wp-timeline.service";
import {ZoomLevel} from "./wp-timeline";
import IDirective = angular.IDirective;
import IScope = angular.IScope;


const template = `
<div style="background-color: #c6eecc">

    HScroll: <input type="number" 
                    ng-model="$ctrl.hscroll" 
                    ng-change="$ctrl.updateScroll()" 
                    style="display: inline-block; width: 200px"/>

    Zoom: <select type="number" 
                  ng-model="$ctrl.zoom" 
                  ng-change="$ctrl.updateZoom()" 
                  style="display: inline-block; width: 200px">
                  
               <option value="${ZoomLevel.DAYS}">Days</option>
               <option value="${ZoomLevel.WEEKS}">Weeks</option>
               <option value="${ZoomLevel.MONTHS}">Months</option>
               <option value="${ZoomLevel.QUARTERS}">Quarter</option>
               <option value="${ZoomLevel.YEARS}">Years</option>
               
         </select>
  
</div>
`;


class WorkPackageTimelineControlController {

  hscroll: number;

  zoom: string;

  /*@ngInject*/
  constructor(private workPackageTimelineService: WorkPackageTimelineService) {
    this.hscroll = workPackageTimelineService.viewParameterSettings.scrollOffsetInDays;
    this.zoom = ZoomLevel.DAYS.toString();
  }

  updateScroll() {
    this.workPackageTimelineService.viewParameterSettings.scrollOffsetInDays = this.hscroll;
    this.workPackageTimelineService.refreshScrollOnly();
  }

  updateZoom() {
    this.workPackageTimelineService.viewParameterSettings.zoomLevel = parseInt(this.zoom);
    this.workPackageTimelineService.refreshView();
  }

}


openprojectModule.component("timelineControl", {
  controller: WorkPackageTimelineControlController,
  template: template
});

