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

import { Chart, InteractionItem, Interaction, InteractionModeFunction } from 'chart.js';
import { getRelativePosition } from 'chart.js/helpers';

declare module 'chart.js' {
  interface InteractionModeMap {
    'series-at-x':InteractionModeFunction;
  }
}

// The built-in index mode reads the same array index from every dataset, which only lines up
// when they share their x values. Series sampled at different rates need matching by position.
//
// A series only reports where it actually runs: the remaining points stop where the projection
// starts, and neither should be read beyond its own span.
export function seriesAtX(chart:Chart, position:{ x:number }, useFinalPosition?:boolean):InteractionItem[] {
  const items:InteractionItem[] = [];

  chart.getSortedVisibleDatasetMetas().forEach((meta) => {
    let closest:InteractionItem|null = null;
    let smallestDistance = Number.POSITIVE_INFINITY;
    let starts = Number.POSITIVE_INFINITY;
    let ends = Number.NEGATIVE_INFINITY;

    meta.data.forEach((element, index) => {
      const { x, skip } = element.getProps(['x', 'skip'], useFinalPosition) as { x:number, skip?:boolean };

      if (skip) {
        return;
      }

      starts = Math.min(starts, x);
      ends = Math.max(ends, x);

      const distance = Math.abs(x - position.x);

      if (distance < smallestDistance) {
        smallestDistance = distance;
        closest = { element, datasetIndex: meta.index, index };
      }
    });

    if (closest && position.x >= starts && position.x <= ends) {
      items.push(closest);
    }
  });

  return items;
}

Interaction.modes['series-at-x'] = (chart, event, _options, useFinalPosition) =>
  seriesAtX(chart, getRelativePosition(event, chart), useFinalPosition);
