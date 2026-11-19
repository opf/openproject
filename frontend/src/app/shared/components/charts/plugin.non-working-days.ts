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

// A plugin for chart.js that renders a background band for non-working days.
// The non-working days behave like a dataset but have no data in the chart.js sense to back it up.
// For every non-working day, the plugin provides a gray background band. Even though days typically
// don't have a time zone, users perceive a day to start at midnight and end at midnight of the next day.
// This makes them subject to the time zone of the chart. While the days are just provided as dates, the zone
// is also passed in and then used to determine the start and end of the day according to that time zone. Most of the
// time, this will be the local time zone of the user.
//
// The non-working days can have a legend and be toggled like any other series. Rather than hand
// rolling that, a caller stands them in with a dataset carrying no points: chart.js draws nothing
// for it, but it earns a legend entry and a visibility that the default legend toggles, and this
// plugin follows it through +datasetIndex+. The painting is hand rolled because there is no data
// for chart.js to draw.

import {
  Animations, Chart, ChartType, Plugin, Scale,
} from 'chart.js';
import moment from 'moment-timezone';
import { getCSSVariable } from 'core-app/shared/helpers/dom-helpers';

export interface NonWorkingInterval {
  from:string;
  to:string;
}

export interface NonWorkingDaysPluginOptions {
  intervals?:NonWorkingInterval[];
  zone?:string;
  // The pointless dataset standing in for the bands, whose visibility they follow. Without one
  // they are always shown, there being nothing to toggle them.
  datasetIndex?:number;
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

// The end of the fade at which the bands are fully shown. How solid they look at that point is
// the color's own business, its alpha included.
const SHOWN_OPACITY = 1;

// An interval covers whole days in +zone+, so it starts at local midnight and runs up to the
// end of its last day rather than its start. Advancing by a day rather than by 24 hours keeps
// a daylight saving transition inside the band -- one falls on a Sunday, so a weekend band
// spans it every autumn and spring.
export function bandFor(interval:NonWorkingInterval, scale:Scale, zone:string):Band|null {
  const from = moment.tz(interval.from, 'YYYY-MM-DD', true, zone);
  const to = moment.tz(interval.to, 'YYYY-MM-DD', true, zone).add(1, 'day');

  if (!from.isValid() || !to.isValid()) {
    return null;
  }

  const left = Math.max(scale.getPixelForValue(from.valueOf()), scale.left);
  const right = Math.min(scale.getPixelForValue(to.valueOf()), scale.right);

  if (right <= left) {
    return null;
  }

  return { left, width: right - left };
}

// Exported so that the dataset standing in for the bands can wear their color in the legend.
export function nonWorkingDaysColor():string {
  return getCSSVariable('--bgColor-neutral-muted', '#818b981f');
}

function bandsShown(chart:Chart, options:NonWorkingDaysPluginOptions):boolean {
  return options.datasetIndex === undefined || chart.isDatasetVisible(options.datasetIndex);
}

interface BandsState {
  opacity:number;
  target:number;
}

const states = new WeakMap<Chart, BandsState>();

// A chart with the animation turned off gets none here either. A scriptable duration is not
// resolvable outside an element's context, so it counts as off rather than being guessed at.
function fadeDuration(chart:Chart):number {
  const animation = chart.options.animation;
  const duration = animation === false ? 0 : animation?.duration;

  return typeof duration === 'number' ? duration : 0;
}

function fade(chart:Chart, state:BandsState, opacity:number):void {
  state.target = opacity;

  new Animations(chart, {
    opacity: { type: 'number', easing: 'easeOutQuart', duration: fadeDuration(chart) },
  }).update(state, { opacity });
}

export const NonWorkingDaysPlugin:Plugin = {
  id: 'non-working-days',

  // Toggling runs through an update, so the fade starts here and the draw only paints it.
  afterUpdate(chart:Chart, _args, options:NonWorkingDaysPluginOptions) {
    const target = bandsShown(chart, options) ? SHOWN_OPACITY : 0;
    const state = states.get(chart);

    if (!state) {
      states.set(chart, { opacity: target, target });
    } else if (state.target !== target) {
      fade(chart, state, target);
    }
  },

  beforeDatasetsDraw(chart:Chart, _args, options:NonWorkingDaysPluginOptions) {
    const intervals = options?.intervals ?? [];
    const scale = chart.scales.x;

    if (intervals.length === 0 || !scale) {
      return;
    }

    const opacity = states.get(chart)?.opacity ?? 0;

    if (opacity <= 0) {
      return;
    }

    const { ctx, chartArea } = chart;

    ctx.save();
    ctx.fillStyle = nonWorkingDaysColor();
    ctx.globalAlpha = opacity;

    const zone = options.zone ?? moment.tz.guess();

    intervals.forEach((interval) => {
      const band = bandFor(interval, scale, zone);

      if (band) {
        ctx.fillRect(band.left, chartArea.top, band.width, chartArea.bottom - chartArea.top);
      }
    });

    ctx.restore();
  },
};

export default NonWorkingDaysPlugin;
