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

import { ChartOptions, TooltipModel } from 'chart.js';
import { html, render } from 'lit-html';
import type { TemplateResult } from 'lit-html';
import type AnchoredPositionElement from '@openproject/primer-view-components/app/components/primer/anchored_position';
import { popoverMessage } from 'core-app/shared/components/anchored-popover/popover-message';
import { syncCaret } from 'core-app/shared/components/anchored-popover/caret-sync';
import type { CaretPlacement } from 'core-app/shared/components/anchored-popover/caret-placement';

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

class ChartTooltip {
  private anchor:DOMRect | null = null;
  private caret:CaretPlacement | null = null;
  private items:TemplateResult[] = [];
  private readonly stopCaretSync:() => void;

  constructor(private readonly host:HTMLElement) {
    this.draw();
    this.stopCaretSync = syncCaret(this.popover, () => this.anchor, (caret) => {
      this.caret = caret;
      this.draw();
    });
  }

  destroy():void {
    this.stopCaretSync();
    this.popover.togglePopover(false);
  }

  update<TType extends 'bar' | 'pie'>(context:TooltipContext<TType>, items:TemplateResult[]):void {
    if (context.tooltip.opacity === 0) {
      this.popover.togglePopover(false);
      return;
    }

    const { left, top } = context.chart.canvas.getBoundingClientRect();
    this.anchor = new DOMRect(Math.round(left + context.tooltip.caretX), Math.round(top + context.tooltip.caretY), 0, 0);
    this.items = items;
    this.caret = null;
    this.draw();
    // Primer's getAnchoredPosition accepts `Element | DOMRect`; the element's
    // setter only narrows the type.
    this.popover.anchorElement = this.anchor as unknown as HTMLElement;
    this.popover.togglePopover(true);
    this.popover.update();
  }

  private get popover():AnchoredPositionElement {
    return this.host.querySelector<AnchoredPositionElement>('anchored-position')!;
  }

  private draw():void {
    render(
      html`
        <anchored-position
          class="op-anchored-popover--host op-chart-tooltip"
          popover="manual"
          side="outside-right"
          align="center"
          anchor-offset="spacious">
          ${popoverMessage(html`<ul class="list-style-none ml-0">${this.items}</ul>`, this.caret)}
        </anchored-position>
      `,
      this.host,
    );
  }
}

function renderColorDot(color:string) {
  return html`<span style="display: inline-block; width: 10px; height: 10px; border-radius: 50%; background: ${color}; vertical-align: baseline; margin-right: 4px"></span>`;
}

function renderTooltipItem(color:string, label:string, formattedValue:string, dateStr?:string):TemplateResult {
  const header = dateStr
    ? html`<div><strong style="margin-right: 8px">${dateStr}</strong>${renderColorDot(color)}<strong>${label}</strong></div>`
    : html`<div>${renderColorDot(color)}<strong>${label}</strong></div>`;
  return html`
    <li class="mb-1">
      ${header}
      <div class="f4" style="font-variant-numeric: tabular-nums">${formattedValue}</div>
    </li>`;
}

export function createBarTooltipRenderer(host:HTMLElement, formatCurrency:FormatCurrency) {
  const tooltip = new ChartTooltip(host);
  const renderer = (context:TooltipContext<'bar'>) => {
    const items = context.tooltip.dataPoints.map((dp, i) => {
      const timestamp = dp.parsed.x;
      const dateStr = timestamp != null
        ? new Date(timestamp).toLocaleDateString(undefined, { month: 'short', year: 'numeric' })
        : undefined;
      const color = context.tooltip.labelColors[i]?.backgroundColor as string;
      return renderTooltipItem(color, dp.dataset.label ?? '', formatCurrency(dp.parsed.y ?? 0), dateStr);
    });
    tooltip.update(context, items);
  };
  return Object.assign(renderer, { destroy: () => tooltip.destroy() });
}

export function createPieTooltipRenderer(host:HTMLElement, formatCurrency:FormatCurrency) {
  const tooltip = new ChartTooltip(host);
  const renderer = (context:TooltipContext<'pie'>) => {
    const items = context.tooltip.dataPoints.map((dp, i) => {
      const color = context.tooltip.labelColors[i]?.backgroundColor as string;
      return renderTooltipItem(color, dp.label ?? '', formatCurrency(dp.parsed));
    });
    tooltip.update(context, items);
  };
  return Object.assign(renderer, { destroy: () => tooltip.destroy() });
}
