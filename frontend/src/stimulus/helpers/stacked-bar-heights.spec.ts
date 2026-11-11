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

import { largestFittingMinBarHours, stackedBarHeights } from './stacked-bar-heights';

const sum = (values:number[]) => values.reduce((total, value) => total + value, 0);

describe('stackedBarHeights', () => {
  it('keeps the true heights without a minimum', () => {
    expect(stackedBarHeights([2, 1], 0)).toEqual([2, 1]);
  });

  it('takes the height added to short bars from the tallest bar only', () => {
    const heights = stackedBarHeights([5, 1.5, 0.75, 0.5, 0.25], 0.75);

    expect(heights).toEqual([4.25, 1.5, 0.75, 0.75, 0.75]);
    expect(sum(heights)).toBe(8);
  });

  it('moves on to the next tallest bar once the tallest one is down to a third', () => {
    const heights = stackedBarHeights([3, 2, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25], 0.75);

    expect(heights[0]).toBeCloseTo(1);
    expect(heights[1]).toBeCloseTo(1);
    expect(sum(heights)).toBeCloseTo(6.5);
  });

  it('lets the stack outgrow the total rather than shrink a bar below a third', () => {
    const heights = stackedBarHeights([3, 0.25, 0.25, 0.25, 0.25, 0.25], 0.75);

    expect(heights[0]).toBeCloseTo(1);
    expect(sum(heights)).toBeCloseTo(4.75);
  });
});

describe('largestFittingMinBarHours', () => {
  const crowdedDay = [5.5, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25];

  it('leaves a long entry at a third of its height when many short ones share its day', () => {
    expect(largestFittingMinBarHours(crowdedDay)).toBeCloseTo((8 - (5.5 / 3)) / 10);
  });

  it('allows every bar the same height when none of them would drop below a third', () => {
    expect(largestFittingMinBarHours([3, 2.5, 1.5, 1])).toBe(2);
  });

  it('returns a minimum at which the stack fits the day total exactly', () => {
    const minBarHours = largestFittingMinBarHours(crowdedDay);

    expect(sum(stackedBarHeights(crowdedDay, minBarHours))).toBeCloseTo(8);
  });
});
