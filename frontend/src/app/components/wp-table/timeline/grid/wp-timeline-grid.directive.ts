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
import {AfterViewInit, Component, ElementRef} from '@angular/core';
import * as moment from 'moment';
import {WorkPackageTimelineTableController} from '../container/wp-timeline-container.directive';
import {
  calculatePositionValueForDayCount,
  getTimeSlicesForHeader,
  timelineElementCssClass,
  timelineGridElementCssClass,
  TimelineViewParameters
} from '../wp-timeline';
import Moment = moment.Moment;
import {TimelineZoomLevel} from 'core-app/modules/hal/resources/query-resource';

function checkForWeekendHighlight(date:Moment, cell:HTMLElement) {
  const day = date.day();

  // Sunday = 0
  // Monday = 6
  if (day === 0 || day === 6) {
    cell.classList.add('grid-weekend');
  }
}

@Component({
  selector: 'wp-timeline-grid',
  template: '<div class="wp-table-timeline--grid"></div>'
})
export class WorkPackageTableTimelineGrid implements AfterViewInit {

  private activeZoomLevel:TimelineZoomLevel;

  private gridContainer:JQuery;

  constructor(private elementRef:ElementRef,
              public wpTimeline:WorkPackageTimelineTableController) {
  }

  ngAfterViewInit() {
    const $element = jQuery(this.elementRef.nativeElement);
    this.gridContainer = $element.find('.wp-table-timeline--grid');
    this.wpTimeline.onRefreshRequested('grid', (vp:TimelineViewParameters) => this.refreshView(vp));
  }

  refreshView(vp:TimelineViewParameters) {
    this.renderLabels(vp);
  }

  private renderLabels(vp:TimelineViewParameters) {
    if (this.activeZoomLevel === vp.settings.zoomLevel) {
      return;
    }

    this.gridContainer.empty();

    switch (vp.settings.zoomLevel) {
      case 'days':
        return this.renderLabelsDays(vp);
      case 'weeks':
        return this.renderLabelsWeeks(vp);
      case 'months':
        return this.renderLabelsMonths(vp);
      case 'quarters':
        return this.renderLabelsQuarters(vp);
      case 'years':
        return this.renderLabelsYears(vp);
    }

    this.activeZoomLevel = vp.settings.zoomLevel;
  }

  private renderLabelsDays(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, 'day', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.style.paddingTop = '1px';
      checkForWeekendHighlight(start, cell);
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('-grid-highlight');
      cell.style.zIndex = '2';
    });
  }

  private renderLabelsWeeks(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, 'day', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      checkForWeekendHighlight(start, cell);
    });

    this.renderTimeSlices(vp, 'week', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('-grid-highlight');
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('-grid-highlight');
      cell.style.zIndex = '2';
    });
  }

  private renderLabelsMonths(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, 'week', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
    });

    this.renderTimeSlices(vp, 'month', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('-grid-highlight');
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('-grid-highlight');
      cell.style.zIndex = '2';
    });
  }

  private renderLabelsQuarters(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, 'month', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
    });

    this.renderTimeSlices(vp, 'quarter', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('-grid-highlight');
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('-grid-highlight');
      cell.style.zIndex = '2';
    });
  }

  private renderLabelsYears(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, 'month', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('-grid-highlight');
    });
  }

  renderTimeSlices(vp:TimelineViewParameters,
                   unit:moment.unitOfTime.DurationConstructor,
                   startView:Moment,
                   endView:Moment,
                   cellCallback:(start:Moment, cell:HTMLElement) => void) {

    const {inViewportAndBoundaries, rest} = getTimeSlicesForHeader(vp, unit, startView, endView);

    for (let [start, end] of inViewportAndBoundaries) {
      const cell = document.createElement('div');
      cell.classList.add(timelineElementCssClass, timelineGridElementCssClass);
      cell.style.left = calculatePositionValueForDayCount(vp, start.diff(startView, 'days'));
      cell.style.width = calculatePositionValueForDayCount(vp, end.diff(start, 'days') + 1);
      this.gridContainer[0].appendChild(cell);
      cellCallback(start, cell);
    }
    setTimeout(() => {
      for (let [start, end] of rest) {
        const cell = document.createElement('div');
        cell.classList.add(timelineElementCssClass, timelineGridElementCssClass);
        cell.style.left = calculatePositionValueForDayCount(vp, start.diff(startView, 'days'));
        cell.style.width = calculatePositionValueForDayCount(vp, end.diff(start, 'days') + 1);
        this.gridContainer[0].appendChild(cell);
        cellCallback(start, cell);
      }
    }, 0);
  }
}
