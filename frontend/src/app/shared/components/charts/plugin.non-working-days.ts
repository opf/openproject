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
// plugin follows it through +datasetIndex+. The painting and its fade still have to be hand rolled,
// because there is no data for chart.js to animate.

import { Chart, ChartType, Plugin, Scale } from 'chart.js';
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

// The bands rendered for the background of non working days are painted by this plugin rather
// than held in a dataset, so nothing animates them when the legend toggles. These reproduce what chart.js
// gives a dataset it hides or shows.
//
// A band settles at full opacity because the colour it is painted in brings its own: the token is a
// background meant to sit under content, so it is already faint. That also leaves the legend swatch,
// which is painted flat, the same weight as the band itself.
const BAND_OPACITY = 1;

interface Fade {
  from:number;
  to:number;
  startedAt:number;
}

// chart.js eases its hide and show transitions with easeOutQuart.
export function fadeOpacity({ from, to }:Fade, progress:number):number {
  const clamped = Math.min(Math.max(progress, 0), 1);

  return from + ((to - from) * (1 - ((1 - clamped) ** 4)));
}

export function fadeProgress(startedAt:number, now:number, duration:number):number {
  return duration <= 0 ? 1 : (now - startedAt) / duration;
}

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

// Exported so that the dataset standing in for the bands can wear their colour in the legend.
export function nonWorkingDaysColor():string {
  return getCSSVariable('--bgColor-neutral-muted', '#818b981f');
}

function bandsShown(chart:Chart, options:NonWorkingDaysPluginOptions):boolean {
  return options.datasetIndex === undefined || chart.isDatasetVisible(options.datasetIndex);
}

// A chart with the animation turned off gets none here either. A scriptable duration is not
// resolvable outside an element's context, so it counts as off rather than being guessed at.
function fadeDuration(chart:Chart):number {
  const animation = chart.options.animation;
  const duration = animation === false ? 0 : animation?.duration;

  return typeof duration === 'number' ? duration : 0;
}

const fades = new WeakMap<Chart, Fade>();
const fading = new WeakSet<Chart>();

function opacityNow(chart:Chart, fade:Fade):number {
  return fadeOpacity(fade, fadeProgress(fade.startedAt, Date.now(), fadeDuration(chart)));
}

// The frames are driven from here rather than from the draw, which chart.js is free to skip
// while its own animator holds the chart -- a fade scheduled from inside one would then never
// be asked for another frame, and would sit frozen until the next toggle snapped it to its end.
function runFade(chart:Chart):void {
  if (fading.has(chart)) {
    return;
  }

  fading.add(chart);

  const step = ():void => {
    const fade = fades.get(chart);

    if (!chart.ctx || !fade) {
      fading.delete(chart);
      return;
    }

    chart.draw();

    if (fadeProgress(fade.startedAt, Date.now(), fadeDuration(chart)) >= 1) {
      fading.delete(chart);
    } else {
      requestAnimationFrame(step);
    }
  };

  requestAnimationFrame(step);
}

export const NonWorkingDaysPlugin:Plugin = {
  id: 'non-working-days',

  // Toggling runs through an update, so the fade starts here and the draw only paints it.
  afterUpdate(chart:Chart, _args, options:NonWorkingDaysPluginOptions) {
    const to = bandsShown(chart, options) ? BAND_OPACITY : 0;
    const previous = fades.get(chart);

    if (!previous) {
      fades.set(chart, { from: to, to, startedAt: 0 });
      return;
    }

    if (previous.to === to) {
      return;
    }

    // Picks up wherever an interrupted fade had reached, so toggling twice quickly does not jump.
    fades.set(chart, { from: opacityNow(chart, previous), to, startedAt: Date.now() });
    runFade(chart);
  },

  beforeDatasetsDraw(chart:Chart, _args, options:NonWorkingDaysPluginOptions) {
    const intervals = options?.intervals ?? [];
    const scale = chart.scales.x;

    if (intervals.length === 0 || !scale) {
      return;
    }

    const settled = bandsShown(chart, options) ? BAND_OPACITY : 0;
    const opacity = opacityNow(chart, fades.get(chart) ?? { from: settled, to: settled, startedAt: 0 });

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
