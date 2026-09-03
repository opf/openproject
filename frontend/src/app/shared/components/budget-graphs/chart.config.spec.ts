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
import { within } from '@testing-library/dom';
import { createBarTooltipRenderer, createPieTooltipRenderer } from './chart.config';
import type { BarTooltipContext } from './chart.config';

describe('chart tooltip renderer', () => {
  let wrapper:HTMLElement;
  let host:HTMLElement;
  let canvas:HTMLCanvasElement;
  let renderers:{ destroy():void }[];

  const nextFrame = () => new Promise(requestAnimationFrame);
  const createRenderer = (formatCurrency:(v:number) => string) => {
    const renderer = createPieTooltipRenderer(host, formatCurrency);
    renderers.push(renderer);
    return renderer;
  };

  beforeEach(() => {
    renderers = [];
    wrapper = document.createElement('div');
    wrapper.style.cssText = 'position: relative; top: 40px; left: 30px;';
    host = document.createElement('div');
    wrapper.append(host);
    canvas = document.createElement('canvas');
    canvas.style.cssText = 'position: fixed; top: 100px; left: 100px; width: 300px; height: 200px;';
    document.body.append(canvas, wrapper);
  });

  afterEach(() => {
    renderers.forEach((renderer) => renderer.destroy());
    wrapper.remove();
    canvas.remove();
  });

  const context = (opacity:number, caretX = 50) => ({
    chart: { canvas },
    tooltip: {
      opacity,
      caretX,
      caretY: 40,
      dataPoints: [{ label: 'Labour', parsed: 1234 }],
      labelColors: [{ backgroundColor: '#123456' }],
    },
  }) as unknown as Parameters<ReturnType<typeof createPieTooltipRenderer>>[0];

  const popover = () => host.querySelector<HTMLElement>('anchored-position')!;
  const message = () => host.querySelector<HTMLElement>('.Popover-message')!;

  it('opens a popover beside the caret point with the formatted value', async () => {
    const renderTooltip = createRenderer((v) => `€${v}`);
    renderTooltip(context(1));

    expect(popover().matches(':popover-open')).toBe(true);
    expect(within(host).getByText('Labour')).toBeInTheDocument();
    expect(within(host).getByText('€1234')).toBeInTheDocument();

    await nextFrame();
    expect(popover().getBoundingClientRect().left).toBeGreaterThanOrEqual(158);
  });

  it('points the caret at the point as soon as it opens', () => {
    createRenderer((v) => `${v}`)(context(1));

    expect(message()).toHaveClass('Popover-message--left');
    expect(message().style.getPropertyValue('--op-anchored-popover-caret-offset')).not.toBe('');
  });

  // Chart.js drives the tooltip from its own animation frame, so the frame
  // anchored-position schedules on reopen only runs after the next paint.
  it('reopens beside the new point before anchored-position gets its frame', async () => {
    const renderTooltip = createRenderer((v) => `${v}`);
    renderTooltip(context(1));
    await nextFrame();
    renderTooltip(context(0));
    await nextFrame();

    const right = await new Promise<number>((resolve) => {
      requestAnimationFrame(() => {
        renderTooltip(context(1, 250));
        resolve(popover().getBoundingClientRect().right);
      });
    });
    expect(right).toBeCloseTo(100 + 250 - 8, 0);
  });

  it('closes the popover when the tooltip fades out', () => {
    const renderTooltip = createRenderer((v) => `${v}`);
    renderTooltip(context(1));
    renderTooltip(context(0));

    expect(popover().matches(':popover-open')).toBe(false);
  });

  const viewportChanges = [
    ['the page scrolls', () => document.dispatchEvent(new Event('scroll'))],
    ['the window is resized', () => window.dispatchEvent(new Event('resize'))],
  ] as const;

  it.each(viewportChanges)('closes the popover when %s', (_, change) => {
    createRenderer((v) => `${v}`)(context(1));
    change();

    expect(popover().matches(':popover-open')).toBe(false);
  });

  it('centres a bar tooltip on the hovered segment', () => {
    const renderTooltip = createBarTooltipRenderer(host, (v) => `${v}`);
    renderers.push(renderTooltip);
    renderTooltip({
      chart: { canvas },
      tooltip: {
        opacity: 1,
        caretX: 50,
        caretY: 20,
        dataPoints: [{
          parsed: { x: 0, y: 10 },
          dataset: { label: 'Labour' },
          element: { getProps: () => ({ x: 50, y: 20, base: 120, width: 30 }) },
        }],
        labelColors: [{ backgroundColor: '#123456' }],
      },
    } as unknown as BarTooltipContext);

    const box = popover().getBoundingClientRect();
    expect(box.left).toBeCloseTo(100 + 65 + 8, 0);
    expect(box.top + box.height / 2).toBeCloseTo(100 + 70, 0);
    expect(message()).toHaveClass('Popover-message--left');
    expect(message().style.getPropertyValue('--op-anchored-popover-caret-offset')).toBe(`${box.height / 2}px`);
  });

  it('never renders into document.body', () => {
    createRenderer((v) => `${v}`)(context(1));
    expect(document.body.querySelector(':scope > anchored-position')).toBeNull();
  });

  it.each(viewportChanges)('stops listening once destroyed when %s', (_, change) => {
    const renderTooltip = createRenderer((v) => `${v}`);
    renderTooltip(context(1));
    renderTooltip.destroy();
    expect(popover().matches(':popover-open')).toBe(false);

    renderTooltip(context(1));
    change();
    expect(popover().matches(':popover-open')).toBe(true);
  });
});
