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

import type { Chart, ChartDataset, ChartType } from 'chart.js';
import PrimerColorsPlugin, { PrimerColorsPluginOptions } from './plugin.primer-colors';
import { createPatternFill, lineDashFor } from './plugin.primer-patterns';

describe('PrimerColorsPlugin', () => {
  const patternTransforms = Array.from({ length: 4 }, () => vi.fn());
  const patterns = patternTransforms.map((setTransform) => ({ setTransform })) as unknown as CanvasPattern[];
  let createPattern:ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.spyOn(window, 'getComputedStyle').mockReturnValue({
      getPropertyValue: vi.fn((property:string) => property),
    } as unknown as CSSStyleDeclaration);
    createPattern = vi.fn()
      .mockReturnValueOnce(patterns[0])
      .mockReturnValueOnce(patterns[1])
      .mockReturnValueOnce(patterns[2])
      .mockReturnValueOnce(patterns[3]);
  });

  afterEach(() => vi.restoreAllMocks());

  function applyPlugin(
    type:ChartType,
    datasets:ChartDataset[],
    labels:string[] = [],
    options:PrimerColorsPluginOptions = {},
  ) {
    const chart = {
      config: { type, data: { datasets, labels } },
      data: { datasets, labels },
      ctx: { createPattern },
      currentDevicePixelRatio: 1,
    } as unknown as Chart;

    if (typeof PrimerColorsPlugin.beforeLayout !== 'function') {
      throw new Error('Primer colors plugin has no beforeLayout hook');
    }

    PrimerColorsPlugin.beforeLayout(chart, { cancelable: true }, { enabled: true, ...options });
  }

  it('uses a solid fill and a pattern for multiple bar datasets', () => {
    const datasets:ChartDataset[] = [
      { label: 'Open', data: [3, 2] },
      { label: 'Closed', data: [1, 4] },
    ];

    applyPlugin('bar', datasets);

    expect(datasets[0].backgroundColor).toEqual([
      '--display-teal-scale-2',
      '--display-teal-scale-2',
    ]);
    expect(datasets[1].backgroundColor).toEqual([patterns[0], patterns[0]]);
    expect(createPattern).toHaveBeenCalledOnce();
  });

  it('keeps the existing colour fills for a single bar dataset', () => {
    const datasets:ChartDataset[] = [{ label: 'Open', data: [3, 2] }];

    applyPlugin('bar', datasets);

    expect(datasets[0].backgroundColor).toEqual([
      '--display-teal-scale-2',
      '--display-orange-scale-2',
    ]);
    expect(createPattern).not.toHaveBeenCalled();
  });

  it('uses line dashes instead of fill patterns for line charts', () => {
    const datasets:ChartDataset[] = [
      { label: 'Open', data: [3, 2] },
      { label: 'Closed', data: [1, 4] },
    ];

    applyPlugin('line', datasets);

    expect((datasets[0] as ChartDataset<'line'>).borderDash).toEqual([]);
    expect((datasets[1] as ChartDataset<'line'>).borderDash).toEqual([8, 4]);
    expect(createPattern).not.toHaveBeenCalled();
  });

  it('uses a different pattern for every bar dataset', () => {
    const datasets:ChartDataset[] = [
      { label: 'First', data: [3] },
      { label: 'Second', data: [2] },
      { label: 'Third', data: [1] },
    ];

    applyPlugin('bar', datasets);

    expect(datasets[0].backgroundColor).toEqual(['--display-teal-scale-2']);
    expect(datasets[1].backgroundColor).toEqual([patterns[0]]);
    expect(datasets[2].backgroundColor).toEqual([patterns[1]]);
  });

  it('uses a different pattern for every labelled pie segment', () => {
    const datasets:ChartDataset[] = [{ label: 'Costs', data: [5, 3, 1] }];

    applyPlugin('pie', datasets, ['Labor', 'Material A', 'Material B'], { labelBased: true });

    expect((datasets[0].backgroundColor as unknown[])[0]).toBeTypeOf('string');
    expect((datasets[0].backgroundColor as unknown[]).slice(1)).toEqual([patterns[0], patterns[1]]);
  });

  it('uses patterns for pie segments without label-based colours', () => {
    const datasets:ChartDataset[] = [{ data: [5, 3, 1] }];

    applyPlugin('pie', datasets);

    expect(datasets[0].backgroundColor).toEqual(['--display-teal-scale-2', patterns[0], patterns[1]]);
  });

  it('provides four patterns in addition to the solid fill', () => {
    const context = { createPattern } as unknown as CanvasRenderingContext2D;

    const fills = [0, 1, 2, 3, 4].map((index) => createPatternFill(context, '#ccc', '#333', index));

    expect(fills).toEqual(['#ccc', ...patterns]);
  });

  it('scales the pattern backing canvas for HiDPI displays', () => {
    const context = { createPattern } as unknown as CanvasRenderingContext2D;

    createPatternFill(context, '#ccc', '#333', 1, 2);

    const tile = createPattern.mock.calls[0][0] as HTMLCanvasElement;
    expect([tile.width, tile.height]).toEqual([16, 16]);
    expect(patternTransforms[0]).toHaveBeenCalledWith({ a: 0.5, d: 0.5 });
  });

  it('reuses an identical pattern for the same chart', () => {
    const context = { createPattern } as unknown as CanvasRenderingContext2D;

    const first = createPatternFill(context, '#ccc', '#333', 1);
    const second = createPatternFill(context, '#ccc', '#333', 6);

    expect(second).toBe(first);
    expect(createPattern).toHaveBeenCalledOnce();
  });

  it('provides all line dash styles', () => {
    expect([0, 1, 2, 3, 4].map((index) => lineDashFor(index))).toEqual([
      [],
      [8, 4],
      [2, 3],
      [8, 3, 2, 3],
      [12, 4],
    ]);
  });
});
