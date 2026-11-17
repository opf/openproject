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

// Based on https://github.com/chartjs/Chart.js/blob/master/src/plugins/plugin.colors.ts

import {
  ChartDataset,
  ChartType,
  Plugin,
} from 'chart.js';
import { getCSSVariable } from 'core-app/shared/helpers/dom-helpers';
import {
  createPatternFill,
  LINE_DASH_COUNT,
  lineDashFor,
  PATTERN_COUNT,
} from './plugin.primer-patterns';

export interface PrimerColorsPluginOptions {
  enabled?:boolean;
  // Color each data point by its axis label (chart.data.labels) — intended for pie/donut charts
  labelBased?:boolean;
  // Color each dataset uniformly by its dataset.label — intended for bar charts
  datasetLabelBased?:boolean;
}

declare module 'chart.js' {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  interface PluginOptionsByType<TType extends ChartType> {
    'primer-colors':PrimerColorsPluginOptions;
  }
}

const PRIMER_COLORS = [
  'teal',   // (fresh contrast)
  'orange', // (bold, warm → most eye-catching → first)
  'green',  // (contrasts strongly with orange)
  'purple', // (cool, distinct)
  'red',    // (strong, but not first to avoid clash with orange)
  'yellow', // (bright highlight, works better later)
  'blue',   // (strong primary)
  'pink',   // (vivid, contrasts with blue)
  'pine',   // (deep green, darker balance)
  'auburn', // (earthy tone)
  'brown',  // (neutral balance)
  'cyan',   // (slight highlight between neutral colors)
  'gray',   // (neutral, mid-series filler)
  'lemon',  // (darker yellow, less eye-catching)
  'olive',  // (subdued green, background tone)
  'lime',   // (subdued green, good closing color)
];

interface PrimerPalette {
  emphasis:string[];
  hoverMuted:string[];
  muted:string[];
}

function resolvePalette():PrimerPalette {
  const styles = getComputedStyle(document.body);
  return {
    emphasis: PRIMER_COLORS.map((color) => getCSSVariable(`--display-${color}-scale-6`, '', styles)),
    hoverMuted: PRIMER_COLORS.map((color) => getCSSVariable(`--display-${color}-scale-3`, '', styles)),
    muted: PRIMER_COLORS.map((color) => getCSSVariable(`--display-${color}-scale-2`, '', styles)),
  };
}

function colorAt(colors:string[], index:number):string {
  return colors[index % colors.length];
}

function fillFor(
  backgroundColor:string,
  foregroundColor:string,
  styleIndex:number,
  context?:CanvasRenderingContext2D,
  devicePixelRatio?:number,
):string|CanvasPattern {
  return context
    ? createPatternFill(context, backgroundColor, foregroundColor, styleIndex, devicePixelRatio)
    : backgroundColor;
}

function colorizePoints(
  dataset:ChartDataset,
  colorIndexes:number[],
  styleIndexes:number[],
  palette:PrimerPalette,
  patternContext?:CanvasRenderingContext2D,
  devicePixelRatio?:number,
):void {
  dataset.backgroundColor = dataset.data.map((_, index) => {
    const colorIndex = colorIndexes[index];
    const mutedColor = colorAt(palette.muted, colorIndex);
    const emphasisColor = colorAt(palette.emphasis, colorIndex);
    return fillFor(mutedColor, emphasisColor, styleIndexes[index], patternContext, devicePixelRatio);
  });
  dataset.hoverBackgroundColor = dataset.data.map((_, index) => {
    const colorIndex = colorIndexes[index];
    return fillFor(
      colorAt(palette.hoverMuted, colorIndex),
      colorAt(palette.emphasis, colorIndex),
      styleIndexes[index],
      patternContext,
      devicePixelRatio,
    );
  });
  dataset.borderColor = dataset.data.map((_, index) => colorAt(palette.emphasis, colorIndexes[index]));
  dataset.borderWidth = 1;
}

function colorizeDataset(
  dataset:ChartDataset,
  colorIndex:number,
  styleIndex:number,
  palette:PrimerPalette,
  context:CanvasRenderingContext2D,
  lineChart:boolean,
  devicePixelRatio:number,
):void {
  const mutedColor = colorAt(palette.muted, colorIndex);
  const hoverMutedColor = colorAt(palette.hoverMuted, colorIndex);
  const emphasisColor = colorAt(palette.emphasis, colorIndex);
  const patternContext = lineChart ? undefined : context;
  const backgroundColor = fillFor(mutedColor, emphasisColor, styleIndex, patternContext, devicePixelRatio);
  const hoverBackgroundColor = fillFor(hoverMutedColor, emphasisColor, styleIndex, patternContext, devicePixelRatio);

  // Instead of directly counting the index up, all elements of that dataset will get the same color
  // Only at the end, we increase so that the next dataset is in a different color
  // See https://community.openproject.org/wp/68364
  dataset.backgroundColor = dataset.data.map(() => backgroundColor);
  dataset.hoverBackgroundColor = dataset.data.map(() => hoverBackgroundColor);
  dataset.borderColor = dataset.data.map(() => emphasisColor);
  dataset.borderWidth = 1;
  if (lineChart) {
    (dataset as ChartDataset<'line'>).borderDash = lineDashFor(styleIndex);
  }
}

// djb2-style XOR hash → stable uint32 for a given label string
function hashLabel(label:string):number {
  let hash = 5381;
  for (let i = 0; i < label.length; i++) {
    hash = ((hash << 5) + hash) ^ label.charCodeAt(i);
    hash = hash >>> 0; // keep as uint32
  }
  return hash;
}

// Process labels in a stable order so input reordering does not change their slots.
function buildLabelIndexMap(labels:string[], slotCount:number):Map<string, number> {
  const items = [...new Set(labels)]
    .map((label) => ({ label, preferred: hashLabel(label) % slotCount }))
    .sort((a, b) => a.preferred - b.preferred || a.label.localeCompare(b.label));

  const used = new Set<number>();
  const map = new Map<string, number>();

  for (const { label, preferred } of items) {
    let slot = preferred;
    if (used.size < slotCount) {
      while (used.has(slot)) {
        slot = (slot + 1) % slotCount;
      }
      used.add(slot);
    }
    map.set(label, slot);
  }

  return map;
}

// Assign colors to a single-dataset chart where each data point has its own label
function assignColorsByLabel(
  dataset:ChartDataset,
  labels:string[],
  palette:PrimerPalette,
  patternContext:CanvasRenderingContext2D|undefined,
  devicePixelRatio:number,
):void {
  const colorMap = buildLabelIndexMap(labels, PRIMER_COLORS.length);
  const styleMap = buildLabelIndexMap(labels, PATTERN_COUNT);
  const colorIndexes = dataset.data.map((_, index) => colorMap.get(labels[index] ?? '') ?? 0);
  const styleIndexes = dataset.data.map((_, index) => styleMap.get(labels[index] ?? '') ?? 0);
  colorizePoints(dataset, colorIndexes, styleIndexes, palette, patternContext, devicePixelRatio);
}

function usesPointPatterns(type:ChartType|undefined):boolean {
  return type === 'pie' || type === 'doughnut' || type === 'polarArea';
}

const plugin:Plugin<ChartType, PrimerColorsPluginOptions> = {
  id: 'primer-colors',
  defaults: { enabled: true },

  beforeLayout(chart, _args, options) {
    if (!options.enabled) {
      return;
    }

    const { data: { datasets } } = chart.config;
    const chartType = 'type' in chart.config ? chart.config.type : undefined;
    const palette = resolvePalette();

    if (options.datasetLabelBased || (options.labelBased && datasets.length !== 1)) {
      const labels = datasets.map((d) => d.label ?? '');
      const colorMap = buildLabelIndexMap(labels, PRIMER_COLORS.length);
      const patternMap = buildLabelIndexMap(labels, PATTERN_COUNT);
      const lineDashMap = buildLabelIndexMap(labels, LINE_DASH_COUNT);
      datasets.forEach((dataset:ChartDataset) => {
        const label = dataset.label ?? '';
        const colorIndex = colorMap.get(label) ?? 0;
        const lineChart = (dataset.type ?? chartType) === 'line';
        colorizeDataset(
          dataset,
          colorIndex,
          (lineChart ? lineDashMap : patternMap).get(label) ?? 0,
          palette,
          chart.ctx,
          lineChart,
          chart.currentDevicePixelRatio,
        );
      });
    } else if (options.labelBased && datasets.length === 1) {
      const datasetType = datasets[0].type ?? chartType;
      assignColorsByLabel(
        datasets[0],
        (chart.data.labels ?? []) as string[],
        palette,
        usesPointPatterns(datasetType) ? chart.ctx : undefined,
        chart.currentDevicePixelRatio,
      );
    } else if (datasets.length === 1) {
      const colorIndexes = datasets[0].data.map((_, index) => index);
      const datasetType = datasets[0].type ?? chartType;
      const pointPatterns = usesPointPatterns(datasetType);
      colorizePoints(
        datasets[0],
        colorIndexes,
        colorIndexes,
        palette,
        pointPatterns ? chart.ctx : undefined,
        chart.currentDevicePixelRatio,
      );
    } else {
      datasets.forEach((dataset:ChartDataset, index) => {
        colorizeDataset(
          dataset,
          index,
          index,
          palette,
          chart.ctx,
          (dataset.type ?? chartType) === 'line',
          chart.currentDevicePixelRatio,
        );
      });
    }
  },
};

export default plugin;
