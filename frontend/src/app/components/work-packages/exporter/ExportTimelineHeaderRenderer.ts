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

// Reduced version of /frontend/src/app/components/wp-table/timeline/header/wp-timeline-header.directive.ts

import * as moment from 'moment';
import Moment = moment.Moment;
import jsPDF from 'jspdf';
import { ExportTimelineConfig } from './ExportTimelineConfig';
import { calculatePositionValueForDayCountingPx, getHeaderHeight } from './utils/utils';


export function renderHeader(doc:jsPDF, config:ExportTimelineConfig) {
  switch (config.zoomLevel) {
    case 'days':
      renderLabelsDays(doc, config);
      break;
    case 'weeks':
      renderLabelsWeeks(doc, config);
      break;
    case 'months':
      renderLabelsMonths(doc, config);
      break;
    case 'quarters':
      renderLabelsQuarters(doc, config);
      break;
    case 'years':
      renderLabelsYears(doc, config);
      break;
  }
  renderHeaderHLines(doc, config);
  renderTodayLine(doc, config);
}

export function renderHeaderHLines(doc:jsPDF, config:ExportTimelineConfig) {
  let left = config.nameColumnSize;
  let width = calculatePositionValueForDayCountingPx(config, config.endDate.diff(config.startDate, 'days') + 1);

  doc.setDrawColor(config.normalLineColor);

  [
    0,
    config.headerLine1Height,
    config.headerLine1Height + config.headerLine2Height,
    config.headerLine1Height + config.headerLine2Height + config.headerLine3Height,
  ].forEach(y => {
    doc.line(left, y, left + width, y);
  })
}

export function renderTodayLine(doc:jsPDF, config:ExportTimelineConfig) {
  let left = config.nameColumnSize;
  let width = calculatePositionValueForDayCountingPx(config, moment({hour: 0, minute: 0, seconds: 0}).diff(config.startDate, 'days') + 1);
  let y = config.headerLine1Height + config.headerLine2Height + config.headerLine3Height;

  doc.setDrawColor(config.todayLineColor);
  doc.setLineDashPattern([5, 5], 0);
  doc.line(left + width, y, left + width, doc.internal.pageSize.height);
  doc.setLineDashPattern([], 0);
}

export function renderLabelsDays(doc:jsPDF, config:ExportTimelineConfig) {
  renderTimeSlices(config, 'month', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('MMM YYYY');
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, 0, left, config.headerLine1Height);
    doc.line(left + width, 0, left + width, config.headerLine1Height);
    doc.text(text, left + width / 2, config.headerLine1Height / 2, {baseline: 'middle', align: 'center'});
  });

  renderTimeSlices(config, 'week', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('ww');
    let y = config.headerLine1Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine2Height);
    doc.line(left + width, y, left + width, y + config.headerLine2Height);
    doc.text(text, left + width / 2, y + config.headerLine2Height / 2, {baseline: 'middle', align: 'center'});
  });

  renderTimeSlices(config, 'day', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('D');
    let y = config.headerLine1Height + config.headerLine2Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine3Height);
    doc.line(left + width, y, left + width, y + config.headerLine3Height);
    doc.text(text, left + width / 2, y + config.headerLine3Height / 3, {baseline: 'middle', align: 'center'});

    text = start.format('dd');
    doc.text(text, left + width / 2, y + config.headerLine3Height * 2 / 3, {baseline: 'middle', align: 'center'});

    // Small vertical line in timeline
    doc.setDrawColor(config.smallLineColor);
    y = getHeaderHeight(config);
    doc.line(left, y, left, doc.internal.pageSize.height);
  });
}

export function renderLabelsWeeks(doc:jsPDF, config:ExportTimelineConfig) {
  renderTimeSlices(config, 'month', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('MMM YYYY');
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, 0, left, config.headerLine1Height);
    doc.line(left + width, 0, left + width, config.headerLine1Height);
    doc.text(text, left + width / 2, config.headerLine1Height / 2, {baseline: 'middle', align: 'center'});
  });

  renderTimeSlices(config, 'week', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('ww');
    let y = config.headerLine1Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine2Height);
    doc.line(left + width, y, left + width, y + config.headerLine2Height);
    doc.text(text, left + width / 2, y + config.headerLine2Height / 2, {baseline: 'middle', align: 'center'});

    // Bold vertical line in timeline
    doc.setDrawColor(config.boldLineColor);
    y = getHeaderHeight(config);
    doc.line(left, y, left, doc.internal.pageSize.height);
  });

  renderTimeSlices(config, 'day', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('D');
    let y = config.headerLine1Height + config.headerLine2Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine3Height);
    doc.line(left + width, y, left + width, y + config.headerLine3Height);
    doc.text(text, left + width / 2, y + config.headerLine3Height / 2, {baseline: 'middle', align: 'center'});

    // Small vertical line in timeline
    doc.setDrawColor(config.smallLineColor);
    y = getHeaderHeight(config);
    doc.line(left, y, left, doc.internal.pageSize.height);
  });
}

export function renderLabelsMonths(doc:jsPDF, config:ExportTimelineConfig) {
  renderTimeSlices(config, 'year', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('YYYY');
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, 0, left, config.headerLine1Height);
    doc.line(left + width, 0, left + width, config.headerLine1Height);
    doc.text(text, left + width / 2, config.headerLine1Height / 2, {baseline: 'middle', align: 'center'});
  });

  renderTimeSlices(config, 'month', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('MMM');
    let y = config.headerLine1Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine2Height);
    doc.line(left + width, y, left + width, y + config.headerLine2Height);
    doc.text(text, left + width / 2, y + config.headerLine2Height / 2, {baseline: 'middle', align: 'center'});

    // Bold vertical line in timeline
    doc.setDrawColor(config.boldLineColor);
    y = getHeaderHeight(config);
    doc.line(left, y, left, doc.internal.pageSize.height);
  });

  renderTimeSlices(config, 'week', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('ww');
    let y = config.headerLine1Height + config.headerLine2Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine3Height);
    doc.line(left + width, y, left + width, y + config.headerLine3Height);
    doc.text(text, left + width / 2, y + config.headerLine3Height / 2, {baseline: 'middle', align: 'center'});

    // Small vertical line in timeline
    doc.setDrawColor(config.smallLineColor);
    y = getHeaderHeight(config);
    doc.line(left, y, left, doc.internal.pageSize.height);
  });
}

export function renderLabelsQuarters(doc:jsPDF, config:ExportTimelineConfig) {
  renderTimeSlices(config, 'year', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('YYYY');
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, 0, left, config.headerLine1Height);
    doc.line(left + width, 0, left + width, config.headerLine1Height);
    doc.text(text, left + width / 2, config.headerLine1Height / 2, {baseline: 'middle', align: 'center'});
  });

  renderTimeSlices(config, 'quarter', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('Q') ;
    let y = config.headerLine1Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine2Height);
    doc.line(left + width, y, left + width, y + config.headerLine2Height);
    doc.text(text, left + width / 2, y + config.headerLine2Height / 2, {baseline: 'middle', align: 'center'});

    // Bold vertical line in timeline
    doc.setDrawColor(config.boldLineColor);
    y = getHeaderHeight(config);
    doc.line(left, y, left, doc.internal.pageSize.height);
  });

  renderTimeSlices(config, 'month', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('MMM');
    let y = config.headerLine1Height + config.headerLine2Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine3Height);
    doc.line(left + width, y, left + width, y + config.headerLine3Height);
    doc.text(text, left + width / 2, y + config.headerLine3Height / 2, {baseline: 'middle', align: 'center'});

    // Small vertical line in timeline
    doc.setDrawColor(config.smallLineColor);
    y = getHeaderHeight(config);
    doc.line(left, y, left, doc.internal.pageSize.height);
  });
}

export function renderLabelsYears(doc:jsPDF, config:ExportTimelineConfig) {
  renderTimeSlices(config, 'year', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('YYYY');
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, 0, left, config.headerLine1Height);
    doc.line(left + width, 0, left + width, config.headerLine1Height);
    doc.text(text, left + width / 2, config.headerLine1Height / 2, {baseline: 'middle', align: 'center'});

    // Bold vertical line in timeline
    doc.setDrawColor(config.boldLineColor);
    let y = getHeaderHeight(config);
    doc.line(left, y, left, doc.internal.pageSize.height);
  });

  renderTimeSlices(config, 'quarter', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('Q');
    let y = config.headerLine1Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine2Height);
    doc.line(left + width, y, left + width, y + config.headerLine2Height);
    doc.text(text, left + width / 2, y + config.headerLine2Height / 2, {baseline: 'middle', align: 'center'});
  });

  renderTimeSlices(config, 'month', config.startDate, config.endDate, (start, left, width) => {
    let text = start.format('M');
    let y = config.headerLine1Height + config.headerLine2Height;
    doc.setDrawColor(config.normalLineColor);
    doc.line(left, y, left, y + config.headerLine3Height);
    doc.line(left + width, y, left + width, y + config.headerLine3Height);
    doc.text(text, left + width / 2, y + config.headerLine3Height / 2, {baseline: 'middle', align: 'center'});

    // Small vertical line in timeline
    doc.setDrawColor(config.smallLineColor);
    y = getHeaderHeight(config);
    doc.line(left, y, left, doc.internal.pageSize.height);
  });
}

export function renderTimeSlices(config:ExportTimelineConfig,
                          unit:moment.unitOfTime.DurationConstructor,
                          startView:Moment,
                          endView:Moment,
                          cellCallback:(start:Moment, left:number, width:number) => void) {

  const cols = getTimeSlicesForHeader(unit, startView, endView);

  for (let [start, end] of cols) {
    let left = calculatePositionValueForDayCountingPx(config, start.diff(startView, 'days'));
    let width = calculatePositionValueForDayCountingPx(config, end.diff(start, 'days') + 1);

    left += config.nameColumnSize;

    cellCallback(start, left, width);
  }
}


export function getTimeSlicesForHeader(unit:moment.unitOfTime.DurationConstructor,
                                       startView:Moment,
                                       endView:Moment) {

  const slices:[Moment, Moment][] = [];

  const time = startView.clone().startOf(unit);
  const end = endView.clone().endOf(unit);

  while (time.isBefore(end)) {
    const sliceStart = moment.max(time, startView).clone();
    const sliceEnd = moment.min(time.clone().endOf(unit), endView).clone();
    time.add(1, unit);
    slices.push([sliceStart, sliceEnd]);
  }

  return slices;
}
