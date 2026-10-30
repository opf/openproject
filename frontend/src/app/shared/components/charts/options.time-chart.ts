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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

// The parts two charts drawn side by side have to agree on: where a day begins, how the axes
// are drawn, and what they are drawn in. Charts reading the same data over the same interval
// should be comparable at a glance, which they stop being as soon as one of them is themed or
// zoned a little differently -- so this is shared rather than copied.
//
// What is left to the caller is what actually differs between them: the series and their
// styling, the interaction mode, the plugins, and the y axis title.

import { ChartOptions } from 'chart.js';
import { getCSSVariable } from 'core-app/shared/helpers/dom-helpers';

const MINUTE_IN_MS = 60 * 1000;

export type ChartStep = 'day'|'hour';

// Structurally satisfied by TimezoneService, which this cannot name without dragging Angular's
// injector into a directory of plain chart helpers.
export interface InstantFormatter {
  formattedDatetimeAsDate(iso:string):string;
  formattedDatetime(iso:string):string;
}

// Ticks sit at the end of the period they describe, so 09:59:59.999 is what the 9 o'clock hour
// left behind and 23:59:59.999 what the day did. The axis draws such a tick on the boundary it
// closes, a millisecond being less than a pixel, so it is named for that boundary too -- the
// hour as 10:00, the day as the date that follows. Rounding away the last second does both, and
// leaves an instant that is genuinely mid-period, such as a sprint's start, where it is.
//
// So a daily tick names the day it opens rather than the one it measured. That is the reading
// the axis forces, the point being drawn on the later gridline, and naming it for the earlier
// day instead put every daily point a gridline away from its own tooltip.
export function formattedTick(timestamp:number, step:ChartStep, formatter:InstantFormatter):string {
  const rounded = new Date(Math.round(timestamp / MINUTE_IN_MS) * MINUTE_IN_MS).toISOString();

  return step === 'day'
    ? formatter.formattedDatetimeAsDate(rounded)
    : formatter.formattedDatetime(rounded);
}

export interface TimeChartOptions {
  // The zone the axis places instants in, which the bands plugin must be told as well, or the
  // two disagree about where a day ends.
  zone:string;
  // Taken across every series rather than the visible ones, so hiding one does not refit the axes.
  range:{ min?:number, max?:number };
  yTitle:string;
  suggestedMax:number|undefined;
  // Given an ISO instant, the date as the reader's OpenProject settings spell it.
  formatDate:(iso:string) => string;
}

type ThemedScales = Pick<ChartOptions<'line'>, 'maintainAspectRatio'|'color'|'scales'>;

export function timeChartOptions({ zone, range, yTitle, suggestedMax, formatDate }:TimeChartOptions):ThemedScales {
  const fontColor = getCSSVariable('--body-font-color', '#333333');
  const gridColor = getCSSVariable('--borderColor-muted', '#d0d7de');

  return {
    maintainAspectRatio: false,
    color: fontColor,
    scales: {
      x: {
        type: 'time',
        ...range,
        adapters: { date: { zone } },
        time: { unit: 'day' },
        ticks: {
          color: fontColor,
          callback: (value:string|number) => formatDate(new Date(Number(value)).toISOString()),
        },
        grid: { color: gridColor },
        border: { color: fontColor },
      },
      y: {
        title: { display: true, text: yTitle, color: fontColor },
        // Whole units only. Callers must be measuring something atomic -- a count of work
        // packages, or a sum of story points, which are integers. A fractional unit such as
        // estimated hours (AGILE-198) would need this lifted to a parameter.
        ticks: { color: fontColor, precision: 0 },
        grid: { color: gridColor },
        border: { color: fontColor },
        beginAtZero: true,
        suggestedMax,
      },
    },
  };
}
