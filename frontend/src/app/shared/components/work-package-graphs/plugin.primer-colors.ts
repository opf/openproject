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

// Based on https://github.com/chartjs/Chart.js/blob/master/src/plugins/plugin.colors.ts

import {
  ChartDataset,
  ChartType,
  Plugin,
} from 'chart.js';

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
  'cyan',   // (slight highlight between neutral colours)
  'gray',   // (neutral, mid-series filler)
  'lemon',  // (darker yellow, less eye-catching)
  'olive',  // (subdued green, background tone)
  'lime',   // (subdued green, good closing color)
];

function getCSSVariable(variable:string) {
  return getComputedStyle(document.body).getPropertyValue(variable).trim();
}

function getEmphasisColors() {
  return PRIMER_COLORS.map((color) => getCSSVariable(`--display-${color}-scale-6`));
}

function getMutedColors() {
  return PRIMER_COLORS.map((color) => getCSSVariable(`--display-${color}-scale-2`));
}

function getEmphasisColor(i:number) {
  return getEmphasisColors()[i % PRIMER_COLORS.length];
}

function getMutedColor(i:number) {
  return getMutedColors()[i % PRIMER_COLORS.length];
}

function colorizeDefaultDataset(dataset:ChartDataset, i:number) {
  return assignColorsForDataset(dataset, i);
}

function assignColorsForDataset(dataset:ChartDataset, i:number):number {
  const backgroundColors:string[] = [];
  const borderColors:string[] = [];

  for (const _ of dataset.data) {
    backgroundColors.push(getMutedColor(i));
    borderColors.push(getEmphasisColor(i));
    i+=1;
  }

  dataset.backgroundColor = backgroundColors;
  dataset.borderColor = borderColors;
  dataset.borderWidth = 1;

  return i;
}

function colorizeMultiDataset(dataset:ChartDataset, i:number) {
  const backgroundColors:string[] = [];
  const borderColors:string[] = [];

  // Instead of directly counting the index up, all elements of that dataset will get the same colour
  // Only at the end, we increase so that the next dataset is in a different colour
  // See https://community.openproject.org/wp/68364
  for (const _ of dataset.data) {
    backgroundColors.push(getMutedColor(i));
    borderColors.push(getEmphasisColor(i));
  }

  dataset.backgroundColor = backgroundColors;
  dataset.borderColor = borderColors;
  dataset.borderWidth = 1;

  return i+1;
}

function getColorizer() {
  let i = 0;

  return (dataset:ChartDataset) => {
    i = colorizeDefaultDataset(dataset, i);
  };
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

// Build a collision-free label→palette-index map.
// Each label's preferred slot is hash(label) % paletteSize.
// If that slot is already claimed, linear-probe to the next free one.
// Processing order: ascending preferred index, alphabetical tie-break — so the
// same algorithm produces identical results for any subset of the same labels.
function buildLabelColorMap(labels:string[]):Map<string, number> {
  const paletteSize = PRIMER_COLORS.length;
  const items = labels
    .map((label) => ({ label, preferred: hashLabel(label) % paletteSize }))
    .sort((a, b) => a.preferred - b.preferred || a.label.localeCompare(b.label));

  const used = new Set<number>();
  const map = new Map<string, number>();

  for (const { label, preferred } of items) {
    let slot = preferred;
    if (used.size < paletteSize) {
      while (used.has(slot)) {
        slot = (slot + 1) % paletteSize;
      }
      used.add(slot);
    }
    map.set(label, slot);
  }

  return map;
}

// Assign colors to a single-dataset chart where each data point has its own label
function assignColorsByLabel(dataset:ChartDataset, labels:string[]):void {
  const colorMap = buildLabelColorMap(labels);
  dataset.backgroundColor = dataset.data.map((_, i) => getMutedColor(colorMap.get(labels[i] ?? '') ?? 0));
  dataset.borderColor = dataset.data.map((_, i) => getEmphasisColor(colorMap.get(labels[i] ?? '') ?? 0));
  dataset.borderWidth = 1;
}

const plugin:Plugin<ChartType, PrimerColorsPluginOptions> = {
  id: 'primer-colors',
  defaults: { enabled: true },

  beforeLayout(chart, _args, options) {
    if (!options.enabled) {
      return;
    }

    const { data: { datasets } } = chart.config;
    if (options.datasetLabelBased || (options.labelBased && datasets.length !== 1)) {
      const labels = datasets.map((d) => d.label ?? '');
      const colorMap = buildLabelColorMap(labels);
      datasets.forEach((dataset:ChartDataset) => {
        colorizeMultiDataset(dataset, colorMap.get(dataset.label ?? '') ?? 0);
      });
    } else if (options.labelBased && datasets.length === 1) {
      assignColorsByLabel(datasets[0], (chart.data.labels ?? []) as string[]);
    } else if (datasets.length === 1) {
      const colorizer = getColorizer();
      datasets.forEach(colorizer);
    } else {
      datasets.forEach((dataset:ChartDataset, index = 0) => {
        colorizeMultiDataset(dataset, index);
      });
    }
  },
};

export default plugin;
