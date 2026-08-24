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

import '@openproject/primer-view-components/app/components/primer/anchored_position';
import { createPieTooltipRenderer } from './chart.config';

describe('chart tooltip renderer', () => {
  let host:HTMLElement;
  let canvas:HTMLCanvasElement;

  beforeEach(() => {
    host = document.createElement('div');
    canvas = document.createElement('canvas');
    canvas.style.cssText = 'position: fixed; top: 100px; left: 100px; width: 300px; height: 200px;';
    document.body.append(canvas, host);
  });

  afterEach(() => {
    host.remove();
    canvas.remove();
  });

  const context = (opacity:number) => ({
    chart: { canvas },
    tooltip: {
      opacity,
      caretX: 50,
      caretY: 40,
      dataPoints: [{ label: 'Labour', parsed: 1234 }],
      labelColors: [{ backgroundColor: '#123456' }],
    },
  }) as unknown as Parameters<ReturnType<typeof createPieTooltipRenderer>>[0];

  const popover = () => host.querySelector<HTMLElement>('anchored-position')!;

  it('opens a popover at the caret point with the formatted value', async () => {
    const renderTooltip = createPieTooltipRenderer(host, (v) => `€${v}`);
    renderTooltip(context(1));

    expect(popover().matches(':popover-open')).toBe(true);
    expect(popover().textContent).toContain('Labour');
    expect(popover().textContent).toContain('€1234');
    expect(host.querySelector('.Popover-message.op-anchored-popover')).not.toBeNull();

    await new Promise(requestAnimationFrame);
    const box = popover().getBoundingClientRect();
    expect(box.left).toBeGreaterThanOrEqual(150);
  });

  it('closes the popover when the tooltip fades out', () => {
    const renderTooltip = createPieTooltipRenderer(host, (v) => `${v}`);
    renderTooltip(context(1));
    renderTooltip(context(0));

    expect(popover().matches(':popover-open')).toBe(false);
  });

  it('never renders into document.body', () => {
    createPieTooltipRenderer(host, (v) => `${v}`)(context(1));
    expect(document.body.querySelector(':scope > anchored-position')).toBeNull();
  });
});
