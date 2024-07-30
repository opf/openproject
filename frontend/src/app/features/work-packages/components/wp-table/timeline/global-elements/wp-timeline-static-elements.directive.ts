//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++
import {
  Component,
  ElementRef,
  OnInit,
} from '@angular/core';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageTimelineTableController } from '../container/wp-timeline-container.directive';
import { calculatePositionValueForDayCountingPx, TimelineViewParameters } from '../wp-timeline';
import {
  TimelineStaticElement,
  timelineStaticElementCssClassname,
} from './timeline-static-element';
import { TodayLineElement } from './wp-timeline.today-line';

@Component({
  selector: 'wp-timeline-static-elements',
  template: '<div class="wp-table-timeline--static-elements"></div>'
})
export class WorkPackageTableTimelineStaticElements implements OnInit {
  public $element:HTMLElement;

  private container:HTMLElement;

  private elements:TimelineStaticElement[];

  constructor(elementRef:ElementRef,
    public states:States,
    public workPackageTimelineTableController:WorkPackageTimelineTableController) {
    this.$element = elementRef.nativeElement;

    this.elements = [
      new TodayLineElement(),
    ];
  }

  ngOnInit() {
    this.container = this.$element.querySelector('.wp-table-timeline--static-elements') as HTMLElement;
    this.workPackageTimelineTableController
      .onRefreshRequested('static elements', (vp:TimelineViewParameters) => this.update(vp));
  }

  private update(vp:TimelineViewParameters) {
    this.removeAllVisibleElements();
    this.renderElements(vp);
  }

  private removeAllVisibleElements() {
    this
      .container
      .querySelectorAll(`.${timelineStaticElementCssClassname}`)
      .forEach((el) => el.remove());
  }

  private renderElements(vp:TimelineViewParameters) {
    for (const e of this.elements) {
      this.container.appendChild(e.render(vp));
    }
    const timelineSide = document.querySelector('.work-packages-tabletimeline--timeline-side');
    if (timelineSide !== null && vp.settings.zoomLevel !== 'auto') {
      const visibleMomentBeforeToday = vp.now.clone().subtract(vp.settings.visibleBeforeTodayInZoomLevel, vp.settings.zoomLevel)
      const visibleDaysBeforeToday = visibleMomentBeforeToday.diff(vp.dateDisplayStart, 'days');
      const visibleDaysBeforeTodayPositionPixels = calculatePositionValueForDayCountingPx(vp, visibleDaysBeforeToday);
      timelineSide.scrollLeft = visibleDaysBeforeTodayPositionPixels;
    }
  }
}
