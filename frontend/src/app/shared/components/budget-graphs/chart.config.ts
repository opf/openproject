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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChartOptions, TooltipModel } from 'chart.js';
import { html, render } from 'lit-html';

export const chartFont:ChartOptions['font'] = {
  family:
    "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji'",
  size: 14,
};

export const chartLegend:ChartOptions['plugins'] = {
  legend: {
    position: 'bottom',
    labels: {
      boxWidth: 56,
      boxHeight: 20,
      padding: 16,
      font: { size: 14 },
    },
  },
};

type FormatCurrency = (value:number) => string;

interface TooltipContext<TType extends 'bar' | 'pie'> {
  chart:{ canvas:HTMLCanvasElement };
  tooltip:TooltipModel<TType>;
}

function applyTooltipPosition<TType extends 'bar' | 'pie'>(
  context:TooltipContext<TType>,
  popoverHtml:ReturnType<typeof html>,
  tooltipId:string,
) {
  render(popoverHtml, document.body);

  const tooltipEl = document.getElementById(tooltipId)!;

  if (context.tooltip.opacity === 0) {
    tooltipEl.style.opacity = '0';
    return;
  }

  const { left, top } = context.chart.canvas.getBoundingClientRect();
  const x = Math.round(left + context.tooltip.caretX);
  const y = Math.round(top + context.tooltip.caretY);

  const wasHidden = !tooltipEl.style.opacity || tooltipEl.style.opacity === '0';
  if (wasHidden) {
    // Snap to position before fading in (avoids sliding from initial 0,0)
    tooltipEl.style.transition = 'none';
    tooltipEl.style.transform = `translate(${x}px, ${y}px)`;
    void tooltipEl.offsetHeight; // force reflow so transform is committed
    tooltipEl.style.transition = 'transform 0.1s ease, opacity 0.15s ease';
  } else {
    tooltipEl.style.transition = 'transform 0.1s ease, opacity 0.15s ease';
    tooltipEl.style.transform = `translate(${x}px, ${y}px)`;
  }

  tooltipEl.style.opacity = '1';
}

function renderColorDot(color:string) {
  return html`<span style="display: inline-block; width: 10px; height: 10px; border-radius: 50%; background: ${color}; vertical-align: baseline; margin-right: 4px"></span>`;
}

function renderTooltipItem(
  color:string,
  label:string,
  formattedValue:string,
  dateStr?:string,
):ReturnType<typeof html> {
  const header = dateStr
    ? html`<div><strong style="margin-right: 8px">${dateStr}</strong>${renderColorDot(color)}<strong>${label}</strong></div>`
    : html`<div>${renderColorDot(color)}<strong>${label}</strong></div>`;
  return html`
    <li class="mb-1">
      ${header}
      <div class="f4" style="font-variant-numeric: tabular-nums">${formattedValue}</div>
    </li>`;
}

function renderTooltipPopover(tooltipId:string, items:ReturnType<typeof html>[]):ReturnType<typeof html> {
  return html`
    <div class="Popover" id="${tooltipId}" style="position: fixed; top: 0; left: 0; pointer-events: none">
      <div class="Box Popover-message Popover-message--left-top ml-2 mx-auto p-2 text-left text-small">
        <ul class="list-style-none ml-0">
          ${items}
        </ul>
      </div>
    </div>`;
}

export function createBarTooltipRenderer(formatCurrency:FormatCurrency) {
  return function(context:TooltipContext<'bar'>) {
    const { tooltip } = context;
    const items = tooltip.dataPoints.map((dp, i) => {
      const timestamp = dp.parsed.x;
      const dateStr = timestamp != null
        ? new Date(timestamp).toLocaleDateString(undefined, { month: 'short', year: 'numeric' })
        : undefined;
      const label = dp.dataset.label ?? '';
      const value = dp.parsed.y ?? 0;
      const color = tooltip.labelColors[i]?.backgroundColor as string;
      return renderTooltipItem(color, label, formatCurrency(value), dateStr);
    });
    applyTooltipPosition(context, renderTooltipPopover('chartjs-tooltip-bar', items), 'chartjs-tooltip-bar');
  };
}

export function createPieTooltipRenderer(formatCurrency:FormatCurrency) {
  return function(context:TooltipContext<'pie'>) {
    const { tooltip } = context;
    const items = tooltip.dataPoints.map((dp, i) => {
      const color = tooltip.labelColors[i]?.backgroundColor as string;
      const label = dp.label ?? '';
      const value = dp.parsed;
      return renderTooltipItem(color, label, formatCurrency(value));
    });
    applyTooltipPosition(context, renderTooltipPopover('chartjs-tooltip-pie', items), 'chartjs-tooltip-pie');
  };
}
