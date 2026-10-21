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

export type RGBA = [number, number, number, number];

export function normalizeHex(value:string):string|null {
  const hex = value.trim().replace(/^#/, '');
  if (/^[\da-f]{3}$/i.test(hex)) {
    return `#${hex.split('').map((channel) => channel.repeat(2)).join('').toUpperCase()}`;
  }
  return /^[\da-f]{6}$/i.test(hex) ? `#${hex.toUpperCase()}` : null;
}

export function composite(foreground:RGBA, background:RGBA):RGBA {
  const alpha = foreground[3] + background[3] * (1 - foreground[3]);
  if (alpha === 0) return [0, 0, 0, 0];
  return [0, 1, 2].map((index) => (
    foreground[index] * foreground[3] + background[index] * background[3] * (1 - foreground[3])
  ) / alpha).concat(alpha) as RGBA;
}

function luminance(color:RGBA):number {
  const linear = color.slice(0, 3).map((channel) => {
    const value = channel / 255;
    return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  });
  return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722;
}

export function contrastRatio(foreground:RGBA, background:RGBA):number {
  const first = luminance(foreground);
  const second = luminance(background);
  return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05);
}

export function formatContrastRatio(ratio:number):string {
  const rounded = ratio.toFixed(2);
  return `${ratio < 4.5 && rounded === '4.50' ? '<' : ''}${rounded}:1`;
}

export function toHex(color:RGBA):string {
  return `#${color.slice(0, 3).map((channel) => Math.round(channel).toString(16).padStart(2, '0')).join('').toUpperCase()}`;
}

export function computedColor(value:string):RGBA {
  const srgb = /^color\(srgb\s+([^)]+)\)$/.exec(value);
  const rgb = /^rgba?\(([^)]+)\)$/.exec(value);
  const match = srgb ?? rgb;
  if (!match) throw new Error(`Unsupported computed color: ${value}`);

  const values = match[1].trim().split(/[\s,/]+/).map(Number);
  if (values.some(Number.isNaN)) throw new Error(`Invalid computed color: ${value}`);

  const channels = values.slice(0, 3).map((channel) => Math.max(0, Math.min(255, channel * (srgb ? 255 : 1))));
  return [...channels, values[3] ?? 1] as RGBA;
}
