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
} from "./wp-timeline";
import {todayLine} from "./wp-timeline.today-line";
import {WorkPackageTimelineTableController} from './wp-timeline-container.directive';
import {InteractiveTableController} from './../../common/interactive-table/interactive-table.directive';
import Moment = moment.Moment;

const cssClassTableBody = ".work-package-table tbody";
const cssClassHeader = ".wp-timeline-header";
const cssHeaderContainer = ".wp-timeline-header-container";

export type GlobalElement = (viewParams: TimelineViewParameters, elem: HTMLElement) => any;
type GlobalElementsRegistry = {[name: string]: GlobalElement};

export class WpTimelineHeader {

  private globalElementsRegistry: GlobalElementsRegistry = {};

  private globalElements: {[type: string]: HTMLElement} = {};

  private headerCell: HTMLElement;
  private outerHeader: JQuery;

  /** UI Scrollbar */
  private scrollBar: JQuery;
  private scrollBarHandle: JQuery;

  private marginTop: number;

  /** Height of the header elements */
  private headerHeight = 45;

  /** Height of the table body + table header */
  private globalHeight: number;

  private activeZoomLevel: ZoomLevel;

  constructor(protected wpTimeline:WorkPackageTimelineTableController) {
    this.addElement("todayline", todayLine);
  }

  refreshView(vp: TimelineViewParameters) {
    this.lazyInit();
    this.renderLabels(vp);
    this.renderGlobalElements(vp);
    this.updateScrollbar(vp);
  }

  addElement(name: string, renderer: GlobalElement) {
    this.globalElementsRegistry[name] = renderer;
  }

  removeElement(name: string) {
    this.globalElements[name].remove();
    delete this.globalElementsRegistry[name];
  }

  setupScrollbar() {
    this.scrollBar = this.outerHeader.find('.wp-timeline--slider');
    this.scrollBar.slider({
         min: 0,
         slide: (evt, ui) => {
           this.wpTimeline.viewParameterSettings.scrollOffsetInDays = -ui.value;
           this.wpTimeline.refreshScrollOnly();

           this.recalculateScrollBarLeftMargin(ui.value);
         }
      });

    this.scrollBarHandle = this.outerHeader.find('.ui-slider-handle');
  }

  private updateScrollbar(vp: TimelineViewParameters) {
    let maxWidth = this.scrollBar.width(),
        daysDisplayed = Math.min(vp.maxSteps, Math.floor(maxWidth / vp.pixelPerDay)),
        newMax = vp.maxSteps - daysDisplayed,
        newWidth = Math.max(Math.min(maxWidth, (vp.maxSteps / vp.pixelPerDay)), 20) + 'px',
        currentValue = this.scrollBar.slider('option', 'value'),
        newValue = Math.min(newMax, currentValue);

    this.scrollBar.slider('option', 'max', newMax);
    this.scrollBarHandle.css('width', newWidth);
    this.scrollBar.slider('option', 'value', newValue);

    this.recalculateScrollBarLeftMargin(newValue);
  }

  // The handle uses left offset to set the current position.
  // With different widths, this causes the slider to move outside the container
  // which we can control through and additional margin-left.
  private recalculateScrollBarLeftMargin(value) {
    let currentMax = this.scrollBar.slider('option', 'max');

     let handleOffset = (currentMax === 0) ? 0 : this.scrollBarHandle.width() * (value / currentMax);
     this.scrollBarHandle.css('margin-left', -1 * handleOffset);
  }

  private lazyInit() {
    if (this.headerCell === undefined) {
      this.headerCell = jQuery(cssClassHeader)[0];
      this.outerHeader = jQuery(cssHeaderContainer);
      this.setupScrollbar();
    }

    this.globalHeight = jQuery(cssClassTableBody).outerHeight() + this.headerHeight;
    this.marginTop = this.headerHeight;
    this.headerCell.style.height = this.globalHeight + 'px';
  }

  private renderLabels(vp: TimelineViewParameters) {
    if (this.activeZoomLevel === vp.settings.zoomLevel) {
      return;
    }

    jQuery(this.headerCell).empty();
    this.globalElements = {};
    this.lazyInit();
    this.renderGlobalElements(vp);

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

  private renderLabelsDays(vp: TimelineViewParameters) {
    this.renderTimeSlices(vp, "month", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM");
    });

    this.renderTimeSlices(vp, "week", 10, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("ww");
      cell.style.borderColor = "#000000";
      cell.style.height = (this.globalHeight - 10) + "px";
      cell.style.zIndex = "2";
    });

    this.renderTimeSlices(vp, "day", 20, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("D");
      cell.style.borderColor = "#CCCCCC";
      cell.style.zIndex = "1";
      cell.style.height = (this.globalHeight - 20) + "px";
    });

    this.renderTimeSlices(vp, "day", 30, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("dd");
      cell.style.borderColor = "#CCCCCC";
      cell.style.borderBottom = "1px solid black";
      cell.style.height = "15px";
    });
  }

  private renderLabelsWeeks(vp: TimelineViewParameters) {
    this.renderTimeSlices(vp, "month", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM");
    });

    this.renderTimeSlices(vp, "week", 10, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("ww");
      cell.style.borderColor = "#000000";
      cell.style.height = (this.globalHeight - 10) + "px";
      cell.style.zIndex = "2";
    });

    this.renderTimeSlices(vp, "day", 20, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("D");
      cell.style.borderColor = "#CCCCCC";
      cell.style.height = "25px";
      cell.style.borderBottom = "1px solid black";
    });
  }

  private renderLabelsMonths(vp: TimelineViewParameters) {
    this.renderTimeSlices(vp, "year", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("YYYY");
    });

    this.renderTimeSlices(vp, "quarter", 10, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("Q");
      cell.style.borderColor = "#000000";
      cell.style.height = (this.globalHeight - 10) + "px";
      cell.style.zIndex = "2";
    });

    this.renderTimeSlices(vp, "month", 20, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MM");
      cell.style.borderColor = "#CCCCCC";
      cell.style.height = "15px";
      cell.style.borderBottom = "1px solid black";
    });
  }

  private renderLabelsQuarters(vp: TimelineViewParameters) {
  }

  private renderLabelsYears(vp: TimelineViewParameters) {
  }


  renderTimeSlices(vp: TimelineViewParameters,
                   unit: string,
                   marginTop: number,
                   startView: Moment,
                   endView: Moment,
                   cellCallback: (start: Moment, cell: HTMLElement) => void) {

    const slices: [Moment, Moment][] = [];

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
      cell.style.borderRight = "1px solid black";
      cell.style.top = marginTop + "px";
      cell.style.left = calculatePositionValueForDayCount(vp, start.diff(startView, "days"));
      cell.style.width = calculatePositionValueForDayCount(vp, end.diff(start, "days") + 1);
      cell.style.textAlign = "center";
      cell.style.fontSize = "8px";
      cellCallback(start, cell);
    }
  }

  private addLabelCell(): HTMLElement {
    const label = document.createElement("div");
    label.className = timelineElementCssClass;
    label.style.position = "absolute";
    label.style.height = "10px";
    label.style.width = "10px";
    label.style.top = "0px";
    label.style.left = "0px";
    label.style.lineHeight = "normal";
    this.headerCell.appendChild(label);
    return label;
  }

  private renderGlobalElements(vp: TimelineViewParameters) {
    const enabledGlobalElements = _.keys(this.globalElementsRegistry);
    const createdGlobalElements = _.keys(this.globalElements);
    const newGlobalElements = _.difference(enabledGlobalElements, createdGlobalElements);

    // new elements
    for (const newElem of newGlobalElements) {
      const elem = document.createElement("div");
      elem.className = timelineElementCssClass + " wp-timeline-global-element-" + newElem;
      elem.style.position = "absolute";
      elem.style.top = this.marginTop + "px";
      elem.style.zIndex = "100";
      this.headerCell.appendChild(elem);
      this.globalElements[newElem] = elem;
    }

    // update elements
    for (const elemType of _.keys(this.globalElements)) {
      const elem = this.globalElements[elemType];
      elem.style.height = this.globalHeight + "px";
      this.globalElementsRegistry[elemType](vp, elem);
    }
  }

}
