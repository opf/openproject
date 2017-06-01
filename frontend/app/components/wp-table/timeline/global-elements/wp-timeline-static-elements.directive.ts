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
import {TimelineStaticElement, timelineStaticElementCssClassname} from "./timeline-static-element";
import {timelineGlobalElementCssClassname} from "./wp-timeline-relations.directive";
import {TodayLineElement} from "./wp-timeline.today-line";


export class WorkPackageTableTimelineStaticElements {

  public wpTimeline:WorkPackageTimelineTableController;

  private container:ng.IAugmentedJQuery;

  private elements:TimelineStaticElement[];

  constructor(public $element:ng.IAugmentedJQuery,
              public $scope:ng.IScope,
              public states:States,
              public wpStates:WorkPackageStates,
              public wpRelations:WorkPackageRelationsService) {

    this.elements = [
      new TodayLineElement()
    ];
  }

  $onInit() {
    this.container = this.$element.find('.wp-table-timeline--static-elements');
    this.wpTimeline.onRefreshRequested('static elements', (vp:TimelineViewParameters) => this.update(vp));
  }

  private update(vp:TimelineViewParameters) {
    this.removeAllVisibleElements();
    this.renderElements(vp);
  }

  private removeAllVisibleElements() {
    jQuery('.' + timelineStaticElementCssClassname).remove();
  }

  private renderElements(vp:TimelineViewParameters) {
    for (const e of this.elements) {
      this.container[0].appendChild(e.render(vp));
    }
  }
}

openprojectModule.component("wpTimelineStaticElements", {
  template: '<div class="wp-table-timeline--static-elements"></div>',
  controller: WorkPackageTableTimelineStaticElements,
  require: {
    wpTimeline: '^wpTimelineContainer'
  }
});
