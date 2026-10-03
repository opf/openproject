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

import {
  Chart, ChartMeta, Element, InteractionItem, Interaction, InteractionModeFunction,
} from 'chart.js';
import { getRelativePosition } from 'chart.js/helpers';

declare module 'chart.js' {
  interface InteractionModeMap {
    'series-at-x':InteractionModeFunction;
  }
}

// The built-in index mode reads the same array index from every dataset, which only lines up
// when they share their x values. Series sampled at different rates need matching by position.
// Series that don't span the same interval as currently hovered, should not be considered at all.
// E.g. on the burndown chart, the "remaining" series is most of the time sampled each hour. The "guideline"
// series spanning the same interval is only sampled once per day. While the sprint is running, the "remaining (projection)"
// starts at the current point in time, which is where "remaining" ends. When hovering over "remaining",
// the matching "guideline" should be found, but not the "remaining (projection)".
export function seriesAtX(chart:Chart, position:{ x:number }, useFinalPosition?:boolean):InteractionItem[] {
  const items:InteractionItem[] = [];

  chart.getSortedVisibleDatasetMetas().forEach((meta) => {
    const index = runningIndex(meta, position.x, useFinalPosition);

    if (index !== -1) {
      items.push({ element: meta.data[index], datasetIndex: meta.index, index });
    }
  });

  return items;
}

interface Placed {
  index:number;
  x:number;
  skip:boolean;
}

function placedAt(points:Element[], index:number, useFinalPosition?:boolean):Placed {
  const { x, skip } = points[index].getProps(['x', 'skip'], useFinalPosition) as { x:number, skip?:boolean };

  return { index, x, skip: skip === true };
}

// A skipped point is a gap in the line: it holds its place in the array, and its x with it, but
// nothing is drawn there. Walks from +from+ in +step+ to the first point that is.
function drawnFrom(points:Element[], from:number, step:number, useFinalPosition?:boolean):Placed|null {
  for (let index = from; index >= 0 && index < points.length; index += step) {
    const placed = placedAt(points, index, useFinalPosition);

    if (!placed.skip) {
      return placed;
    }
  }

  return null;
}

// In ascending order the cursor falls between two neighboring points, and only those two can be
// nearest to it. Each step looks at the middle of what is left and throws away the half the cursor
// is not in, so a series of any length is read about a dozen points deep rather than end to end.
// The ends are read first: they are the span the series runs over, which decides whether it counts
// at all, and they seed the halving without a further read.
//
// A dataset chart.js has not ordered has no such pair and would be read wrongly rather than
// slowly, so it is refused outright. Emptiness is settled first: a dataset standing in for
// something drawn by other means carries no points, and is neither ordered nor needs to be.
function runningIndex(meta:ChartMeta, x:number, useFinalPosition?:boolean):number {
  const points = meta.data;
  let low = drawnFrom(points, 0, 1, useFinalPosition);
  let high = drawnFrom(points, points.length - 1, -1, useFinalPosition);

  if (!low || !high) {
    return -1;
  }

  // eslint-disable-next-line no-underscore-dangle -- chart.js names it, and it is typed
  if (!meta._sorted) {
    throw new Error('The series-at-x interaction mode needs every dataset ordered by x');
  }

  if (x < low.x || x > high.x) {
    return -1;
  }

  while (high.index - low.index > 1) {
    const middle = placedAt(points, (low.index + high.index) >>> 1, useFinalPosition);

    if (middle.x <= x) {
      low = middle;
    } else {
      high = middle;
    }
  }

  // A gap can leave the halving standing on a point that is not drawn, so the nearest drawn one
  // to either side takes its place.
  const left = low.skip ? drawnFrom(points, low.index, -1, useFinalPosition) : low;
  const right = high.skip ? drawnFrom(points, high.index, 1, useFinalPosition) : high;

  if (!left || !right) {
    return (left ?? right)?.index ?? -1;
  }

  return x - left.x <= right.x - x ? left.index : right.index;
}

Interaction.modes['series-at-x'] = (chart, event, _options, useFinalPosition) =>
  seriesAtX(chart, getRelativePosition(event, chart), useFinalPosition);
