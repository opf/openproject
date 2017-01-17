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
import {WorkPackageTimelineTableController} from "./wp-timeline-container.directive";
import * as noUiSlider from "nouislider";
import Moment = moment.Moment;

const cssClassTableBody = ".work-package-table tbody";
const cssClassTableContainer = ".generic-table--results-container";
const cssClassHeader = ".wp-timeline-header";
const cssHeaderContainer = ".wp-timeline-header-container";
const scrollBarHeight = 16;

export type GlobalElement = (viewParams: TimelineViewParameters, elem: HTMLElement) => any;
type GlobalElementsRegistry = {[name: string]: GlobalElement};

export class WpTimelineHeader {

  private globalElementsRegistry: GlobalElementsRegistry = {};

  private globalElements: {[type: string]: HTMLElement} = {};

  private headerCell: HTMLElement;
  private outerHeader: JQuery;

  /** UI Scrollbar */
  private scrollBar: HTMLElement;
  private scrollWrapper: JQuery;
  private scrollBarHandle: JQuery;
  private scrollBarOrigin: JQuery;

  private marginTop: number;

  /** Height of the header elements */
  private headerHeight = 45;

  /** Height of the table body + table header */
  private globalHeight: number;

  /** The total outer height available to the wrapping container */
  private containerHeight: number;

  private activeZoomLevel: ZoomLevel;

  constructor(protected wpTimeline: WorkPackageTimelineTableController) {
    this.addElement("todayline", todayLine);
  }

  refreshView(vp: TimelineViewParameters) {
    this.lazyInit();
    this.renderLabels(vp);
    this.renderGlobalElements(vp);
    this.updateScrollbar(vp);
  }

  getHeaderWidth() {
    return this.outerHeader ? this.outerHeader.width() : 1;
  }

  addElement(name: string, renderer: GlobalElement) {
    this.globalElementsRegistry[name] = renderer;
  }

  removeElement(name: string) {
    this.globalElements[name].remove();
    delete this.globalElementsRegistry[name];
  }

  setupScrollbar() {
    this.scrollWrapper = jQuery('.wp-timeline--slider-wrapper');
    this.scrollBar = this.scrollWrapper.find('.wp-timeline--slider')[0];
    noUiSlider.create(this.scrollBar, {
      start: [0],
      range: {
        min: [0],
        max: [100]
      },
      orientation: 'horizontal',
      tooltips: false,
    });

    this.sliderInstance.on('update', (values: any[]) => {
      let value = values[0];
      this.wpTimeline.viewParameterSettings.scrollOffsetInDays = -value;
      this.wpTimeline.refreshScrollOnly();
    });

    this.scrollBarHandle = this.scrollWrapper.find('.noUi-handle');
    this.scrollBarOrigin = this.scrollWrapper.find('.noUi-origin');
  }

  public addScrollDelta(delta) {
    const value = (this.wpTimeline.viewParameterSettings.scrollOffsetInDays += delta);
    this.sliderInstance.set(-value);
    this.wpTimeline.refreshScrollOnly();
  }

  // noUiSlider doesn't extend the HTMLElement interface
  // and thus requires casting for now.
  private get sliderInstance(): noUiSlider.noUiSlider {
    return (this.scrollBar as noUiSlider.Instance).noUiSlider;
  }

  private updateScrollbar(vp: TimelineViewParameters) {
    const headerWidth = this.getHeaderWidth();

    // Update the scrollbar to match the current width
    this.scrollWrapper.css('width', headerWidth + 'px');

    // Re-position the scrollbar depending on the global height
    // It should not be any larger than the container height
    if (this.containerHeight > (this.globalHeight + scrollBarHeight)) {
      this.scrollWrapper.css('top', this.globalHeight + 'px');
    } else {
      this.scrollWrapper.css('top', (this.containerHeight - scrollBarHeight) + 'px');
    }

    let maxWidth = headerWidth,
      daysDisplayed = Math.min(vp.maxSteps, Math.floor(maxWidth / vp.pixelPerDay)),
      newMax = Math.max(vp.maxSteps - daysDisplayed, 1),
      currentValue = <number> this.sliderInstance.get(),
      newValue = Math.min(newMax, currentValue),
      desiredWidth, newWidth, cssWidth;

    // Compute the actual width of the handle depending on the scrollable content
    // The width should be no smaller than 30px
    desiredWidth = Math.max(vp.maxSteps / vp.pixelPerDay, (40 - vp.pixelPerDay)) * 2;

    // The actual width should be no larger than the actual width of the scrollbar
    // If the entirety of the timeline is already visible, hide the scrollbar
    if (newMax === 1) {
      newWidth = maxWidth;
      this.scrollWrapper.hide();
    } else {
      this.scrollWrapper.show();
      newWidth = Math.min(maxWidth, desiredWidth);
    }

    let newCssWidth = newWidth + 'px';

    // With changed widths, we need to correct the
    // - right padding of the scrollbar (avoid right boundary traversal)
    // - width of the actual handle
    // - offset for origin of the slider.
    jQuery(this.scrollBar).css('padding-right', (newWidth - 1) + 'px');
    this.scrollBarHandle.css('width', newCssWidth);
    this.scrollBarOrigin.css('right', '-' + newCssWidth);

    (this.sliderInstance as any).updateOptions({
      start: newValue,
      range: {
        min: 0,
        max: newMax
      }
    });
  }

  private lazyInit() {
    if (this.headerCell === undefined) {
      this.headerCell = jQuery(cssClassHeader)[0];
      this.outerHeader = jQuery(cssHeaderContainer);
      this.setupScrollbar();
    }

    this.containerHeight = jQuery(cssClassTableContainer).outerHeight() + this.headerHeight;
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

    this.renderTimeSlices(vp, "month", 10, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM");
      cell.style.borderColor = "#000000";
      cell.style.height = (this.globalHeight - 10) + "px";
    });

    this.renderTimeSlices(vp, "week", 20, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("ww");
      cell.style.borderColor = "#CCCCCC";
      cell.style.height = "25px";
      cell.style.borderBottom = "1px solid black";
      cell.style.backgroundColor = "white";
    });
  }

  private renderLabelsQuarters(vp: TimelineViewParameters) {
    this.renderTimeSlices(vp, "year", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("YYYY");
    });

    this.renderTimeSlices(vp, "quarter", 10, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = "Q" + start.format("Q");
      cell.style.borderColor = "#000000";
      cell.style.height = (this.globalHeight - 10) + "px";
    });

    this.renderTimeSlices(vp, "month", 20, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("MMM");
      cell.style.borderColor = "#000000";
      cell.style.height = "25px";
      cell.style.borderBottom = "1px solid black";
      cell.style.backgroundColor = "white";
    });
  }

  private renderLabelsYears(vp: TimelineViewParameters) {
    this.renderTimeSlices(vp, "year", 0, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("YYYY");
      cell.style.backgroundColor = "white";
    });

    this.renderTimeSlices(vp, "quarter", 10, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = "Q" + start.format("Q");
      cell.style.borderColor = "#000000";
      cell.style.height = (this.globalHeight - 10) + "px";
    });

    this.renderTimeSlices(vp, "month", 20, vp.dateDisplayStart, vp.dateDisplayEnd, (start, cell) => {
      cell.innerHTML = start.format("M");
      cell.style.borderColor = "#000000";
      cell.style.height = "25px";
      cell.style.borderBottom = "1px solid black";
      cell.style.backgroundColor = "white";
    });
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
