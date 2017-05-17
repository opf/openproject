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
  TimelineViewParameters,
  timelineElementCssClass,
  ZoomLevel,
  calculatePositionValueForDayCount
} from "../wp-timeline";
import {WorkPackageTimelineTableController} from "../container/wp-timeline-container.directive";
import * as moment from 'moment';
import Moment = moment.Moment;
import {openprojectModule} from "../../../../angular-modules";

export const timelineHeaderCSSClass = 'wp-timeline--header-element';

export class WorkPackageTimelineHeaderController {

  public wpTimeline:WorkPackageTimelineTableController;

  private activeZoomLevel:ZoomLevel;

  private innerHeader:ng.IAugmentedJQuery;

  constructor(public $element:ng.IAugmentedJQuery) {
  }

  $onInit() {
    this.wpTimeline.onRefreshRequested('header', (vp:TimelineViewParameters) => this.refreshView(vp));
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

    switch (vp.settings.zoomLevel) {
      case ZoomLevel.DAYS:
        return this.renderLabelsDays(vp);
      case ZoomLevel.WEEKS:
        return this.renderLabelsWeeks(vp);
      case ZoomLevel.MONTHS:
        return this.renderLabelsMonths(vp);
      case ZoomLevel.QUARTERS:
        return this.renderLabelsQuarters(vp);
      case ZoomLevel.YEARS:
        return this.renderLabelsYears(vp);
    }

    this.activeZoomLevel = vp.settings.zoomLevel;
  }

  private renderLabelsDays(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, "month", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM YYYY");
      cell.classList.add('wp-timeline--header-top-bold-element');
      cell.style.height = "13px";
    });

    this.renderTimeSlices(vp, "week", 13, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("ww");
      cell.classList.add('-top-border');
      cell.style.height = '32px';
    });

    this.renderTimeSlices(vp, "day", 23, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("D");
      cell.classList.add('-top-border');
      cell.style.height = '22px';
    });

    this.renderTimeSlices(vp, "day", 33, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("dd");
      cell.classList.add('wp-timeline--header-day-element');
    });
  }

  private renderLabelsWeeks(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, "month", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM YYYY");
      cell.classList.add('wp-timeline--header-top-bold-element');
    });

    this.renderTimeSlices(vp, "week", 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("ww");
      cell.classList.add('-top-border');
      cell.style.height = '22px';
    });

    this.renderTimeSlices(vp, "day", 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("D");
      cell.classList.add('wp-timeline--header-middle-element');
    });
  }

  private renderLabelsMonths(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, "year", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("YYYY");
      cell.classList.add('wp-timeline--header-top-bold-element');
    });

    this.renderTimeSlices(vp, "month", 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM");
      cell.classList.add('-top-border');
      cell.style.height = '30px';
    });

    this.renderTimeSlices(vp, "week", 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("ww");
      cell.classList.add('wp-timeline--header-middle-element');
    });
  }

  private renderLabelsQuarters(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, "year", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.classList.add('wp-timeline--header-top-bold-element');
      cell.innerHTML = start.format("YYYY");
    });

    this.renderTimeSlices(vp, "quarter", 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = "Q" + start.format("Q");
      cell.classList.add('-top-border');
      cell.style.height = '30px';
    });

    this.renderTimeSlices(vp, "month", 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM");
      cell.classList.add('wp-timeline--header-middle-element');
    });
  }

  private renderLabelsYears(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, "year", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("YYYY");
      cell.classList.add('wp-timeline--header-top-bold-element');

    });

    this.renderTimeSlices(vp, "quarter", 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = "Q" + start.format("Q");
      cell.classList.add('-top-border');
      cell.style.height = '30px';
    });

    this.renderTimeSlices(vp, "month", 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("M");
      cell.classList.add('wp-timeline--header-middle-element');
    });
  }

  renderTimeSlices(vp:TimelineViewParameters,
                   unit:moment.unitOfTime.DurationConstructor,
                   marginTop:number,
                   startView:Moment,
                   endView:Moment,
                   cellCallback:(start:Moment, cell:HTMLElement) => void) {

    const slices:[Moment, Moment][] = [];

    const time = startView.clone().startOf(unit);
    const end = endView.clone().endOf(unit);

    while (time.isBefore(end)) {
      const sliceStart = moment.max(time, startView).clone();
      const sliceEnd = moment.min(time.clone().endOf(unit), endView).clone();
      time.add(1, unit);
      slices.push([sliceStart, sliceEnd]);
    }

    for (let [start, end] of slices) {
      const cell = this.addLabelCell();
      cell.style.top = marginTop + "px";
      cell.style.left = calculatePositionValueForDayCount(vp, start.diff(startView, "days"));
      cell.style.width = calculatePositionValueForDayCount(vp, end.diff(start, "days") + 1);
      cellCallback(start, cell);
    }
  }

  private addLabelCell():HTMLElement {
    const label = document.createElement("div");
    label.className = timelineHeaderCSSClass;

    this.innerHeader.append(label);
    return label;
  }
}

openprojectModule.component("wpTimelineHeader", {
  templateUrl: '/components/wp-table/timeline/header/wp-timeline-header.html',
  controller: WorkPackageTimelineHeaderController,
  require: {
    wpTimeline: '^wpTimelineContainer'
  }
});
