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
import {Component, ElementRef, OnInit} from '@angular/core';
import {States} from '../../../states.service';
import {WorkPackageTimelineTableController} from '../container/wp-timeline-container.directive';
import {TimelineViewParameters} from '../wp-timeline';
import {TimelineStaticElement, timelineStaticElementCssClassname} from './timeline-static-element';
import {TodayLineElement} from './wp-timeline.today-line';

@Component({
  selector: 'wp-timeline-static-elements',
  template: '<div class="wp-table-timeline--static-elements"></div>'
})
export class WorkPackageTableTimelineStaticElements implements OnInit {

  public $element:JQuery;

  private container:JQuery;

  private elements:TimelineStaticElement[];

  constructor(elementRef:ElementRef,
              public states:States,
              public workPackageTimelineTableController:WorkPackageTimelineTableController) {

    this.$element = jQuery(elementRef.nativeElement);

    this.elements = [
      new TodayLineElement()
    ];
  }

  ngOnInit() {
    this.container = this.$element.find('.wp-table-timeline--static-elements');
    this.workPackageTimelineTableController
      .onRefreshRequested('static elements', (vp:TimelineViewParameters) => this.update(vp));
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
