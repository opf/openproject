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

// The share of its height a bar keeps when it gives height to bars raised to the minimum,
// so that a long entry still reads as one.
const MIN_KEPT_SHARE = 1 / 3;

const sum = (values:number[]) => values.reduce((total, value) => total + value, 0);

// The heights of one day's bars. Bars raised to the minimum height take that height back
// from the tallest bars, so that the top of the stack still lines up with the day's total
// and medium bars keep enough height for their full card.
export function stackedBarHeights(hours:number[], minBarHours:number):number[] {
  const heights = hours.map((value) => Math.max(value, minBarHours));
  let addedByFloor = sum(heights) - sum(hours);

  [...heights.keys()]
    .sort((a, b) => heights[b] - heights[a])
    .forEach((index) => {
      const taken = Math.min(
        heights[index] - minBarHours,
        heights[index] * (1 - MIN_KEPT_SHARE),
        addedByFloor,
      );
      heights[index] -= taken;
      addedByFloor -= taken;
    });

  return heights;
}

// The tallest minimum bar height at which a day's bars still fit into its total, when each
// bar keeps at least MIN_KEPT_SHARE of its own height. The shortest bars end up at the
// minimum and the rest at their kept share, so this tries ever fewer bars at the minimum
// until the minimum is no lower than the kept share of the tallest bar among them.
export function largestFittingMinBarHours(hours:number[]):number {
  const keptShares = hours.map((value) => value * MIN_KEPT_SHARE).sort((a, b) => a - b);

  for (let atMinimum = keptShares.length; atMinimum > 0; atMinimum--) {
    const keptAtShare = sum(keptShares.slice(atMinimum));
    const minBarHours = (sum(hours) - keptAtShare) / atMinimum;

    if (minBarHours >= keptShares[atMinimum - 1]) {
      return minBarHours;
    }
  }

  return 0;
}
