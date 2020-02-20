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
import {TimelineZoomLevel} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageTimelineTableController} from 'core-components/wp-table/timeline/container/wp-timeline-container.directive';
import * as moment from 'moment';
import {
  calculatePositionValueForDayCount,
  getTimeSlicesForHeader,
  timelineHeaderCSSClass,
  timelineHeaderSelector,
  TimelineViewParameters
} from '../wp-timeline';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageViewTimelineService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import Moment = moment.Moment;

@Component({
  selector: timelineHeaderSelector,
  templateUrl: './wp-timeline-header.html'
})
export class WorkPackageTimelineHeaderController implements OnInit {

  public $element:JQuery;

  private activeZoomLevel:TimelineZoomLevel;

  private innerHeader:JQuery;

  constructor(elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly wpTimelineService:WorkPackageViewTimelineService,
              readonly workPackageTimelineTableController:WorkPackageTimelineTableController) {

    this.$element = jQuery(elementRef.nativeElement);
  }

  ngOnInit() {
    this.workPackageTimelineTableController
      .onRefreshRequested('header', (vp:TimelineViewParameters) => this.refreshView(vp));
  }

  refreshView(vp:TimelineViewParameters) {
    this.innerHeader = this.$element.find('.wp-table-timeline--header-inner');
    this.renderLabels(vp);
  }

  private renderLabels(vp:TimelineViewParameters) {
    if (this.activeZoomLevel === vp.settings.zoomLevel) {
      return;
    }

    this.innerHeader.empty();
    this.innerHeader.attr('data-current-zoom-level', this.wpTimelineService.zoomLevel);

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
    this.renderTimeSlices(vp, 'month', 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('MMM YYYY');
      cell.classList.add('wp-timeline--header-top-bold-element');
      cell.style.height = '13px';
    });

    this.renderTimeSlices(vp, 'week', 13, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('ww');
      cell.classList.add('-top-border');
      cell.style.height = '32px';
    });

    this.renderTimeSlices(vp, 'day', 23, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('D');
      cell.classList.add('-top-border');
      cell.style.height = '22px';
    });

    this.renderTimeSlices(vp, 'day', 33, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('dd');
      cell.classList.add('wp-timeline--header-day-element');
    });
  }

  private renderLabelsWeeks(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, 'month', 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('MMM YYYY');
      cell.classList.add('wp-timeline--header-top-bold-element');
    });

    this.renderTimeSlices(vp, 'week', 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('ww');
      cell.classList.add('-top-border');
      cell.style.height = '22px';
    });

    this.renderTimeSlices(vp, 'day', 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('D');
      cell.classList.add('wp-timeline--header-middle-element');
    });
  }

  private renderLabelsMonths(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, 'year', 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('YYYY');
      cell.classList.add('wp-timeline--header-top-bold-element');
    });

    this.renderTimeSlices(vp, 'month', 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('MMM');
      cell.classList.add('-top-border');
      cell.style.height = '30px';
    });

    this.renderTimeSlices(vp, 'week', 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('ww');
      cell.classList.add('wp-timeline--header-middle-element');
    });
  }

  private renderLabelsQuarters(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, 'year', 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--header-top-bold-element');
      cell.innerHTML = start.format('YYYY');
    });

    this.renderTimeSlices(vp, 'quarter', 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = this.I18n.t('js.timelines.quarter_label',
        { quarter_number: start.format('Q') });
      cell.classList.add('-top-border');
      cell.style.height = '30px';
    });

    this.renderTimeSlices(vp, 'month', 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('MMM');
      cell.classList.add('wp-timeline--header-middle-element');
    });
  }

  private renderLabelsYears(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, 'year', 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('YYYY');
      cell.classList.add('wp-timeline--header-top-bold-element');

    });

    this.renderTimeSlices(vp, 'quarter', 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = this.I18n.t('js.timelines.quarter_label',
        { quarter_number: start.format('Q') });
      cell.classList.add('-top-border');
      cell.style.height = '30px';
    });

    this.renderTimeSlices(vp, 'month', 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format('M');
      cell.classList.add('wp-timeline--header-middle-element');
    });
  }

  private renderTimeSlices(vp:TimelineViewParameters,
                           unit:moment.unitOfTime.DurationConstructor,
                           marginTop:number,
                           startView:Moment,
                           endView:Moment,
                           cellCallback:(start:Moment, cell:HTMLElement) => void) {

    const {inViewportAndBoundaries, rest} = getTimeSlicesForHeader(vp, unit, startView, endView);

    for (let [start, end] of inViewportAndBoundaries) {
      const cell = this.addLabelCell();
      cell.style.top = marginTop + 'px';
      cell.style.left = calculatePositionValueForDayCount(vp, start.diff(startView, 'days'));
      cell.style.width = calculatePositionValueForDayCount(vp, end.diff(start, 'days') + 1);
      cellCallback(start, cell);
    }
    setTimeout(() => {
      for (let [start, end] of rest) {
        const cell = this.addLabelCell();
        cell.style.top = marginTop + 'px';
        cell.style.left = calculatePositionValueForDayCount(vp, start.diff(startView, 'days'));
        cell.style.width = calculatePositionValueForDayCount(vp, end.diff(start, 'days') + 1);
        cellCallback(start, cell);
      }
    }, 0);
  }

  private addLabelCell():HTMLElement {
    const label = document.createElement('div');
    label.className = timelineHeaderCSSClass;

    this.innerHeader.append(label);
    return label;
  }
}
