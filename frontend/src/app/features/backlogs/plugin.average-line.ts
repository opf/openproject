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

import { Chart, ChartType, Plugin } from 'chart.js';
import { toFont } from 'chart.js/helpers';

export interface AverageLinePluginOptions {
  value?:number;
  label?:string;
  color?:string;
  labelColor?:string;
}

declare module 'chart.js' {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  interface PluginOptionsByType<TType extends ChartType> {
    averageLine:AverageLinePluginOptions;
  }
}

export const AVERAGE_LINE_DASH = [4, 4];
const LABEL_PADDING = 8;

const chartsWithHiddenLine = new WeakSet<Chart>();

export function isAverageLineVisible(chart:Chart):boolean {
  return !chartsWithHiddenLine.has(chart);
}

export function toggleAverageLine(chart:Chart):void {
  if (isAverageLineVisible(chart)) {
    chartsWithHiddenLine.add(chart);
  } else {
    chartsWithHiddenLine.delete(chart);
  }
  chart.update();
}

function labelText(options:AverageLinePluginOptions):string {
  return options.label ?? String(options.value);
}

function labelFont(chart:Chart):string {
  return toFont({ weight: 'bold' }, chart.options.font).string;
}

const AverageLinePlugin:Plugin<ChartType, AverageLinePluginOptions> = {
  id: 'averageLine',

  afterLayout(chart, _args, options) {
    const xScale = chart.scales.x;
    if (options.value === undefined || !xScale) {
      return;
    }

    const { ctx } = chart;
    ctx.save();
    ctx.font = labelFont(chart);
    const inset = ctx.measureText(labelText(options)).width + (2 * LABEL_PADDING);
    ctx.restore();

    xScale.left += inset;
    xScale.width -= inset;
    xScale.configure();
  },

  beforeDatasetsDraw(chart, _args, options) {
    const yScale = chart.scales.y;
    if (options.value === undefined || !yScale || !isAverageLineVisible(chart)) {
      return;
    }

    const { ctx, chartArea } = chart;
    const y = yScale.getPixelForValue(options.value);
    const color = options.color ?? 'gray';

    ctx.save();

    ctx.strokeStyle = color;
    ctx.lineWidth = 1;
    ctx.setLineDash(AVERAGE_LINE_DASH);
    ctx.beginPath();
    ctx.moveTo(chart.scales.x?.left ?? chartArea.left, y);
    ctx.lineTo(chartArea.right, y);
    ctx.stroke();

    ctx.fillStyle = options.labelColor ?? color;
    ctx.font = labelFont(chart);
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';
    ctx.fillText(labelText(options), chartArea.left + LABEL_PADDING, y);

    ctx.restore();
  },
};

export default AverageLinePlugin;
