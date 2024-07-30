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
  AfterViewInit,
  Component,
  ElementRef,
} from '@angular/core';
import * as moment from 'moment';
import { TimelineZoomLevel } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageTimelineTableController } from '../container/wp-timeline-container.directive';
import {
  calculatePositionValueForDayCount,
  getTimeSlicesForHeader,
  timelineElementCssClass,
  timelineGridElementCssClass,
  TimelineViewParameters,
} from '../wp-timeline';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import Moment = moment.Moment;

@Component({
  selector: 'wp-timeline-grid',
  template: '<div class="wp-table-timeline--grid"></div>',
})
export class WorkPackageTableTimelineGrid implements AfterViewInit {
  private activeZoomLevel:TimelineZoomLevel;

  private gridContainer:JQuery;

  constructor(
    private elementRef:ElementRef,
    public wpTimeline:WorkPackageTimelineTableController,
    private weekdaysService:WeekdayService,
  ) {}

  ngAfterViewInit():void {
    const $element = jQuery(this.elementRef.nativeElement);
    this.gridContainer = $element.find('.wp-table-timeline--grid');
    this.wpTimeline.onRefreshRequested('grid', (vp:TimelineViewParameters) => this.refreshView(vp));
  }

  refreshView(vp:TimelineViewParameters):void {
    this.renderLabels(vp);
  }

  private renderLabels(vp:TimelineViewParameters):void {
    this.gridContainer.empty();

    switch (vp.settings.zoomLevel) {
      case 'days':
        this.renderLabelsDays(vp);
        break;
      case 'weeks':
        this.renderLabelsWeeks(vp);
        break;
      case 'months':
        this.renderLabelsMonths(vp);
        break;
      case 'quarters':
        this.renderLabelsQuarters(vp);
        break;
      case 'years':
        this.renderLabelsYears(vp);
        break;
      default:
        return;
    }

    this.activeZoomLevel = vp.settings.zoomLevel;
  }

  private renderLabelsDays(vp:TimelineViewParameters):void {
    this.renderTimeSlices(vp, 'day', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.style.paddingTop = '1px';
      this.checkForNonWorkingDayHighlight(start, cell);
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--grid-element_highlight');
      cell.style.zIndex = '2';
    });
  }

  private renderLabelsWeeks(vp:TimelineViewParameters):void {
    this.renderTimeSlices(vp, 'day', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      this.checkForNonWorkingDayHighlight(start, cell);
    });

    this.renderTimeSlices(vp, 'week', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--grid-element_highlight');
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--grid-element_highlight');
      cell.style.zIndex = '2';
    });
  }

  private renderLabelsMonths(vp:TimelineViewParameters):void {
    this.renderTimeSlices(vp, 'week', vp.dateDisplayStart, vp.dateDisplayEnd, () => {
    });

    this.renderTimeSlices(vp, 'month', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--grid-element_highlight');
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--grid-element_highlight');
      cell.style.zIndex = '2';
    });
  }

  private renderLabelsQuarters(vp:TimelineViewParameters):void {
    this.renderTimeSlices(vp, 'month', vp.dateDisplayStart, vp.dateDisplayEnd, () => {
    });

    this.renderTimeSlices(vp, 'quarter', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--grid-element_highlight');
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--grid-element_highlight');
      cell.style.zIndex = '2';
    });
  }

  private renderLabelsYears(vp:TimelineViewParameters):void {
    this.renderTimeSlices(vp, 'month', vp.dateDisplayStart, vp.dateDisplayEnd, () => {
    });

    this.renderTimeSlices(vp, 'year', vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--grid-element_highlight');
    });
  }

  renderTimeSlices(vp:TimelineViewParameters,
    unit:moment.unitOfTime.DurationConstructor,
    startView:Moment,
    endView:Moment,
    cellCallback:(start:Moment, cell:HTMLElement) => void):void {
    const { inViewportAndBoundaries, rest } = getTimeSlicesForHeader(vp, unit, startView, endView);

    for (const [start, end] of inViewportAndBoundaries) {
      const cell = document.createElement('div');
      cell.classList.add(timelineElementCssClass, timelineGridElementCssClass);
      cell.style.left = calculatePositionValueForDayCount(vp, start.diff(startView, 'days'));
      cell.style.width = calculatePositionValueForDayCount(vp, end.diff(start, 'days') + 1);
      this.gridContainer[0].appendChild(cell);
      cellCallback(start, cell);
    }
    setTimeout(() => {
      for (const [start, end] of rest) {
        const cell = document.createElement('div');
        cell.classList.add(timelineElementCssClass, timelineGridElementCssClass);
        cell.style.left = calculatePositionValueForDayCount(vp, start.diff(startView, 'days'));
        cell.style.width = calculatePositionValueForDayCount(vp, end.diff(start, 'days') + 1);
        this.gridContainer[0].appendChild(cell);
        cellCallback(start, cell);
      }
    }, 0);
  }

  private checkForNonWorkingDayHighlight(date:Moment, cell:HTMLElement) {
    const day = date.toDate();
    if (this.weekdaysService.isNonWorkingDay(day) || this.wpTimeline.isNonWorkingDay(day)) {
      cell.classList.add('wp-timeline--non-working-day');
      cell.dataset.testSelector = `wp-timeline--non-working-day_${day.getDate()}-${day.getMonth() + 1}-${day.getFullYear()}`;
    }
  }
}
