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
import {todayLine} from "../wp-timeline.today-line";
import {WorkPackageTimelineTableController} from "../container/wp-timeline-container.directive";
import * as moment from 'moment';
import Moment = moment.Moment;
import {openprojectModule} from "../../../../angular-modules";

const colorGrey1 = "#AAAAAA";
const colorGrey2 = "#DDDDDD";

export class WorkPackageTimelineHeaderController {

  public wpTimeline:WorkPackageTimelineTableController;

  private activeZoomLevel:ZoomLevel;

  private innerHeader:ng.IAugmentedJQuery;

  constructor(public $element:ng.IAugmentedJQuery) {
  }

  $onInit() {
    this.wpTimeline.header = this;
  }

  refreshView(vp:TimelineViewParameters) {
    this.innerHeader = this.$element.find('.wp-table-timeline--header-inner');
    this.renderLabels(vp);
  }

  getHeaderWidth():number {
    // Consider the left margin of the header due to the border.
    return this.$element.width();
  }

  getAbsoluteLeftCoordinates():number {
    return this.$element.offset().left;
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
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.fontWeight = "bold";
      cell.style.fontSize = "10px";
      cell.style.height = "13px";
    });

    this.renderTimeSlices(vp, "week", 13, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("ww");
      cell.style.borderColor = `${colorGrey1}`;
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.height = '32px';
      cell.style.zIndex = "2";
    });

    this.renderTimeSlices(vp, "day", 23, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("D");
      cell.style.borderColor = `${colorGrey2}`;
      cell.style.zIndex = "1";
      cell.style.height = '22px';
      cell.style.borderTop = `1px solid ${colorGrey1}`;
    });

    this.renderTimeSlices(vp, "day", 33, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("dd");
      cell.style.height = "12px";
      cell.style.paddingTop = "1px";
      cell.style.borderBottom = `1px solid ${colorGrey1}`;
    });
  }

  private renderLabelsWeeks(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, "month", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.innerHTML = start.format("MMM YYYY");
      cell.style.fontWeight = "bold";
      cell.style.fontSize = "12px";
      cell.style.height = "15px";
    });

    this.renderTimeSlices(vp, "week", 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("ww");
      cell.style.borderColor = `${colorGrey1}`;
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.height = '22px';
      cell.style.zIndex = "2";
    });

    this.renderTimeSlices(vp, "day", 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("D");
      cell.style.borderColor = `${colorGrey1}`;
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.paddingTop = "5px";
      cell.style.height = "20px";
      cell.style.borderBottom = `1px solid ${colorGrey1}`;
    });
  }

  private renderLabelsMonths(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, "year", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.innerHTML = start.format("YYYY");
      cell.style.fontWeight = "bold";
      cell.style.fontSize = "12px";
      cell.style.height = "15px";
    });

    this.renderTimeSlices(vp, "month", 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM");
      cell.style.borderColor = `${colorGrey2}`;
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.height = '32px';
    });

    this.renderTimeSlices(vp, "week", 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("ww");
      cell.style.borderColor = `${colorGrey1}`;
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.height = "20px";
      cell.style.paddingTop = "5px";
      cell.style.height = "20px";
      cell.style.borderBottom = `1px solid ${colorGrey1}`;
    });
  }

  private renderLabelsQuarters(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, "year", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.innerHTML = start.format("YYYY");
      cell.style.fontWeight = "bold";
      cell.style.fontSize = "12px";
      cell.style.height = "15px";
    });

    this.renderTimeSlices(vp, "quarter", 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = "Q" + start.format("Q");
      cell.style.borderColor = `${colorGrey2}`;
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.height = '32px';
    });

    this.renderTimeSlices(vp, "month", 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM");
      cell.style.height = "20px";
      cell.style.borderColor = `${colorGrey2}`;
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.paddingTop = "5px";
      cell.style.height = "20px";
      cell.style.borderBottom = `1px solid ${colorGrey1}`;
    });
  }

  private renderLabelsYears(vp:TimelineViewParameters) {
    this.renderTimeSlices(vp, "year", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("YYYY");
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.borderColor = `${colorGrey1}`;
      cell.style.backgroundColor = "white";
      cell.style.fontWeight = "bold";
      cell.style.fontSize = "12px";
      cell.style.height = "15px";
    });

    this.renderTimeSlices(vp, "quarter", 15, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = "Q" + start.format("Q");
      cell.style.borderColor = `${colorGrey2}`;
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.height = '32px';
    });

    this.renderTimeSlices(vp, "month", 25, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("M");
      cell.style.borderColor = `${colorGrey2}`;
      cell.style.borderTop = `1px solid ${colorGrey1}`;
      cell.style.height = "20px";
      cell.style.paddingTop = "5px";
      cell.style.height = "20px";
      cell.style.borderBottom = `1px solid ${colorGrey1}`;
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
      cell.style.borderRight = `1px solid ${colorGrey1}`;
      cell.style.top = marginTop + "px";
      cell.style.left = calculatePositionValueForDayCount(vp, start.diff(startView, "days"));
      cell.style.width = calculatePositionValueForDayCount(vp, end.diff(start, "days") + 1);
      cell.style.textAlign = "center";
      cell.style.fontSize = "8px";
      cellCallback(start, cell);
    }
  }

  private addLabelCell():HTMLElement {
    const label = document.createElement("div");
    label.className = timelineElementCssClass;
    label.style.position = "absolute";
    label.style.height = "10px";
    label.style.width = "10px";
    label.style.top = "0px";
    label.style.left = "0px";
    label.style.lineHeight = "normal";
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
