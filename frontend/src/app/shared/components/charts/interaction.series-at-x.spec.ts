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

import { Chart } from 'chart.js';
import { SeriesAtXPlugin, seriesAtX } from './interaction.series-at-x';

function element(x:number, skip = false) {
  return { getProps: () => ({ x, skip }) };
}

// Remaining runs to the middle of the chart, where the projection takes over. The order the mode
// reads these in is SeriesAtXPlugin's to hold, so the metas carry no verdict about it.
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

  // The non-working days stand in with a dataset of no points, so that the legend can toggle what
  // a plugin paints. There is no span to place the cursor against.
  it('passes over a dataset with no points', () => {
    const chart = {
      getSortedVisibleDatasetMetas: () => [
        { index: 0, data: [] },
        { index: 1, data: [element(0), element(50)] },
      ],
    } as unknown as Chart;

    expect(seriesAtX(chart, { x: 25 }).map((item) => item.datasetIndex)).toEqual([1]);
  });

  it('reads a sorted series a few points deep rather than end to end', () => {
    const counted = (x:number) => {
      let reads = 0;

      return {
        reads: () => reads,
        element: { getProps: () => { reads += 1; return { x, skip: false }; } },
      };
    };

    const points = [0, 10, 20, 30, 40, 50, 60, 70, 80].map(counted);
    const chart = {
      getSortedVisibleDatasetMetas: () => [
        { index: 0, _sorted: true, data: points.map((point) => point.element) },
      ],
    } as unknown as Chart;

    seriesAtX(chart, { x: 10 });

    // Both ends for the span, then the middle of each surviving half: 40, 20, and 10 itself.
    expect(points.map((point) => point.reads())).toEqual([1, 1, 1, 0, 1, 0, 0, 0, 1]);
  });

  // A gap holds its place on the axis -- chart.js skips a point whose value is null but still
  // places it at its own x -- so the halving can narrow onto one and then step off it.
  it('steps off a gap the halving lands on', () => {
    const chart = {
      getSortedVisibleDatasetMetas: () => [
        { index: 0, _sorted: true, data: [element(0), element(10, true), element(20)] },
      ],
    } as unknown as Chart;

    expect(seriesAtX(chart, { x: 10 }).map((item) => item.index)).toEqual([0]);
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

describe('SeriesAtXPlugin', () => {
  interface Meta { label?:string, sorted:boolean, points:number, hidden?:boolean }

  function updating(metas:Meta[], options:unknown = { interaction: { mode: 'series-at-x' } }):() => void {
    const metaAt = (index:number) => ({
      index,
      label: metas[index].label,
      hidden: metas[index].hidden === true,
      _sorted: metas[index].sorted,
      data: new Array<unknown>(metas[index].points).fill(element(0)),
    });

    const chart = {
      options,
      data: { datasets: metas.map(() => ({})) },
      getDatasetMeta: metaAt,
      // Offered so that a plugin reading only what is on screen would pass the hidden case below.
      getSortedVisibleDatasetMetas: () => metas.map((_meta, index) => metaAt(index)).filter((meta) => !meta.hidden),
    } as unknown as Chart;

    return () => SeriesAtXPlugin.beforeDatasetsUpdate?.(chart, { mode: 'default' }, {});
  }

  const unordered = [{ sorted: true, points: 3 }, { label: 'Guideline', sorted: false, points: 2 }];

  it('lets a chart whose datasets are all ordered update', () => {
    expect(updating([{ sorted: true, points: 3 }, { sorted: true, points: 2 }])).not.toThrow();
  });

  // Refusing here rather than on the cursor's arrival: the mode would read such a dataset wrongly
  // rather than slowly, and would do it on every movement.
  it('refuses a chart carrying a dataset chart.js has not ordered, naming it', () => {
    expect(updating(unordered)).toThrow(/"Guideline"/);
  });

  // The plugin is registered globally alongside the mode, so it meets every chart in the
  // application and has to leave alone the ones reading their series some other way.
  it('passes over a chart that does not ask for the mode', () => {
    expect(updating(unordered, { interaction: { mode: 'nearest' } })).not.toThrow();
    expect(updating(unordered, {})).not.toThrow();
  });

  // Hover and the tooltip fall back to interaction, so a chart naming the mode on one of those
  // alone still means it.
  it('holds a chart that asks for the mode on its hover or its tooltip', () => {
    expect(updating(unordered, { hover: { mode: 'series-at-x' } })).toThrow(/ordered by x/);
    expect(updating(unordered, { plugins: { tooltip: { mode: 'series-at-x' } } })).toThrow(/ordered by x/);
  });

  // chart.js never parses a dataset with nothing in it, so it stays unordered for good.
  it('passes over a dataset with no points, which is never marked ordered', () => {
    expect(updating([{ sorted: false, points: 0 }, { sorted: true, points: 2 }])).not.toThrow();
  });

  // Hidden datasets are parsed like the rest, so the toggle that reveals one finds it already held
  // to the order rather than breaking the chart at that point.
  it('holds a dataset hidden from the legend to the same order', () => {
    expect(updating([{ sorted: true, points: 3 }, { label: 'Hidden', sorted: false, points: 2, hidden: true }]))
      .toThrow(/ordered by x/);
  });
});
