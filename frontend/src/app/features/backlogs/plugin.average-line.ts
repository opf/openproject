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

import { ChartType, Plugin } from 'chart.js';
import { toFont } from 'chart.js/helpers';

export interface AverageLinePluginOptions {
  value?:number;
  label?:string;
  color?:string;
}

declare module 'chart.js' {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  interface PluginOptionsByType<TType extends ChartType> {
    averageLine:AverageLinePluginOptions;
  }
}

const LABEL_PADDING = 8;

const AverageLinePlugin:Plugin<ChartType, AverageLinePluginOptions> = {
  id: 'averageLine',

  beforeDatasetsDraw(chart, _args, options) {
    const yScale = chart.scales.y;
    if (options.value === undefined || !yScale) {
      return;
    }

    const { ctx, chartArea } = chart;
    const y = yScale.getPixelForValue(options.value);
    const color = options.color ?? 'gray';

    ctx.save();

    ctx.strokeStyle = color;
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    ctx.moveTo(chartArea.left, y);
    ctx.lineTo(chartArea.right, y);
    ctx.stroke();

    ctx.fillStyle = color;
    ctx.font = toFont(chart.options.font ?? {}).string;
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';
    ctx.fillText(options.label ?? String(options.value), yScale.right - LABEL_PADDING, y);

    ctx.restore();
  },
};

export default AverageLinePlugin;
