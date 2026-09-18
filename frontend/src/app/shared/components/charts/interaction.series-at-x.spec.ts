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

import { Chart } from 'chart.js';
import { seriesAtX } from './interaction.series-at-x';

function element(x:number, skip = false) {
  return { getProps: () => ({ x, skip }) };
}

// Remaining runs to the middle of the chart, where the projection takes over.
function chartStub():Chart {
  return {
    getSortedVisibleDatasetMetas: () => [
      { index: 0, data: [element(0), element(25), element(50)] },
      { index: 1, data: [element(50), element(75), element(100)] },
      { index: 2, data: [element(0), element(50), element(100)] },
    ],
  } as unknown as Chart;
}

describe('seriesAtX', () => {
  it('reports every series running at that position', () => {
    expect(seriesAtX(chartStub(), { x: 50 }).map((item) => item.datasetIndex)).toEqual([0, 1, 2]);
  });

  it('leaves out a series that has not started yet', () => {
    expect(seriesAtX(chartStub(), { x: 20 }).map((item) => item.datasetIndex)).toEqual([0, 2]);
  });

  it('leaves out a series that has already ended', () => {
    expect(seriesAtX(chartStub(), { x: 80 }).map((item) => item.datasetIndex)).toEqual([1, 2]);
  });

  it('picks the closest point of each running series', () => {
    expect(seriesAtX(chartStub(), { x: 30 }).map((item) => item.index)).toEqual([1, 1]);
  });

  it('ignores skipped points when deciding where a series runs', () => {
    const chart = {
      getSortedVisibleDatasetMetas: () => [
        { index: 0, data: [element(0), element(90, true)] },
      ],
    } as unknown as Chart;

    expect(seriesAtX(chart, { x: 80 })).toEqual([]);
  });
});
