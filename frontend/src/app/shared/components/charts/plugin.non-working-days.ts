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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Chart, ChartType, Plugin, Scale } from 'chart.js';

export interface NonWorkingInterval {
  from:string;
  to:string;
}

export interface NonWorkingDaysPluginOptions {
  intervals?:NonWorkingInterval[];
  hidden?:boolean;
}

declare module 'chart.js' {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  interface PluginOptionsByType<TType extends ChartType> {
    'non-working-days':NonWorkingDaysPluginOptions;
  }
}

export interface Band {
  left:number;
  width:number;
}

// An interval covers whole days, so it runs up to the end of its last day rather than its start.
export function bandFor(interval:NonWorkingInterval, scale:Scale):Band|null {
  const from = Date.parse(`${interval.from}T00:00:00Z`);
  const to = Date.parse(`${interval.to}T00:00:00Z`) + 24 * 60 * 60 * 1000;

  if (Number.isNaN(from) || Number.isNaN(to)) {
    return null;
  }

  const left = Math.max(scale.getPixelForValue(from), scale.left);
  const right = Math.min(scale.getPixelForValue(to), scale.right);

  if (right <= left) {
    return null;
  }

  return { left, width: right - left };
}

function bandColor():string {
  return getComputedStyle(document.body).getPropertyValue('--borderColor-muted').trim() || '#d0d7de';
}

export const NonWorkingDaysPlugin:Plugin = {
  id: 'non-working-days',

  beforeDatasetsDraw(chart:Chart, _args, options:NonWorkingDaysPluginOptions) {
    const intervals = options?.intervals ?? [];
    const scale = chart.scales.x;

    if (options?.hidden || intervals.length === 0 || !scale) {
      return;
    }

    const { ctx, chartArea } = chart;

    ctx.save();
    ctx.fillStyle = bandColor();
    ctx.globalAlpha = 0.5;

    intervals.forEach((interval) => {
      const band = bandFor(interval, scale);

      if (band) {
        ctx.fillRect(band.left, chartArea.top, band.width, chartArea.bottom - chartArea.top);
      }
    });

    ctx.restore();
  },
};

export default NonWorkingDaysPlugin;
