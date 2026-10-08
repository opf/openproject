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

import type { Chart } from 'chart.js';
import AverageLinePlugin, { AverageLinePluginOptions } from './plugin.average-line';

describe('AverageLinePlugin', () => {
  let ctx:Record<string, unknown> & {
    save:ReturnType<typeof vi.fn>;
    restore:ReturnType<typeof vi.fn>;
    beginPath:ReturnType<typeof vi.fn>;
    moveTo:ReturnType<typeof vi.fn>;
    lineTo:ReturnType<typeof vi.fn>;
    stroke:ReturnType<typeof vi.fn>;
    setLineDash:ReturnType<typeof vi.fn>;
    fillText:ReturnType<typeof vi.fn>;
  };
  let getPixelForValue:ReturnType<typeof vi.fn>;

  beforeEach(() => {
    ctx = {
      save: vi.fn(),
      restore: vi.fn(),
      beginPath: vi.fn(),
      moveTo: vi.fn(),
      lineTo: vi.fn(),
      stroke: vi.fn(),
      setLineDash: vi.fn(),
      fillText: vi.fn(),
    };
    getPixelForValue = vi.fn().mockReturnValue(120);
  });

  const chartStub = (withYScale = true) => ({
    ctx,
    chartArea: { left: 40, right: 400, top: 10, bottom: 250 },
    scales: withYScale ? { y: { getPixelForValue, right: 36 } } : {},
    options: { font: { family: 'sans-serif', size: 12 } },
  } as unknown as Chart);

  const draw = (options:AverageLinePluginOptions, chart = chartStub()) => {
    AverageLinePlugin.beforeDatasetsDraw!(chart, { cancelable: true }, options);
  };

  it('draws nothing without a value', () => {
    draw({ label: '42', color: 'red' });

    expect(ctx.save).not.toHaveBeenCalled();
    expect(ctx.stroke).not.toHaveBeenCalled();
    expect(ctx.fillText).not.toHaveBeenCalled();
  });

  it('draws nothing without a y scale', () => {
    draw({ value: 42 }, chartStub(false));

    expect(ctx.stroke).not.toHaveBeenCalled();
    expect(ctx.fillText).not.toHaveBeenCalled();
  });

  it('draws a dashed line across the full chart area at the value', () => {
    draw({ value: 42.5, color: 'red' });

    expect(getPixelForValue).toHaveBeenCalledWith(42.5);
    expect(ctx.setLineDash).toHaveBeenCalledWith([4, 4]);
    expect(ctx.moveTo).toHaveBeenCalledWith(40, 120);
    expect(ctx.lineTo).toHaveBeenCalledWith(400, 120);
    expect(ctx.stroke).toHaveBeenCalledTimes(1);
    expect(ctx.strokeStyle).toBe('red');
  });

  it('writes the label right-aligned next to the y axis', () => {
    draw({ value: 42.5, label: '42,5', color: 'red' });

    expect(ctx.fillText).toHaveBeenCalledWith('42,5', 28, 120);
    expect(ctx.textAlign).toBe('right');
    expect(ctx.textBaseline).toBe('middle');
    expect(ctx.fillStyle).toBe('red');
    expect(ctx.font).toContain('sans-serif');
  });

  it('falls back to the raw value and a neutral color', () => {
    draw({ value: 7 });

    expect(ctx.fillText).toHaveBeenCalledWith('7', 28, 120);
    expect(ctx.strokeStyle).toBe('gray');
  });

  it('restores the canvas state after drawing', () => {
    draw({ value: 7 });

    expect(ctx.save).toHaveBeenCalledTimes(1);
    expect(ctx.restore).toHaveBeenCalledTimes(1);
  });
});
