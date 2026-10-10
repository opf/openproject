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

const PATTERN_SIZE = 8;
const PATTERN_COUNT = 5;
const patternCache = new WeakMap<CanvasRenderingContext2D, Map<string, CanvasPattern>>();

export function createPatternFill(
  context:CanvasRenderingContext2D,
  backgroundColor:string,
  foregroundColor:string,
  index:number,
  devicePixelRatio = 1,
):string|CanvasPattern {
  const pattern = index % PATTERN_COUNT;
  if (pattern === 0) return backgroundColor;

  const scale = devicePixelRatio || 1;
  const cache = patternCache.get(context) ?? new Map<string, CanvasPattern>();
  const cacheKey = `${backgroundColor}:${foregroundColor}:${pattern}:${scale}`;
  const cachedPattern = cache.get(cacheKey);
  if (cachedPattern) return cachedPattern;

  const tile = document.createElement('canvas');
  tile.width = PATTERN_SIZE * scale;
  tile.height = PATTERN_SIZE * scale;

  const tileContext = tile.getContext('2d');
  if (!tileContext) return backgroundColor;

  tileContext.scale(scale, scale);
  tileContext.fillStyle = backgroundColor;
  tileContext.fillRect(0, 0, PATTERN_SIZE, PATTERN_SIZE);
  tileContext.fillStyle = foregroundColor;
  tileContext.strokeStyle = foregroundColor;
  tileContext.lineWidth = 1.5;

  if (pattern === 3) {
    drawDots(tileContext);
  } else {
    drawLines(tileContext, pattern);
  }

  const canvasPattern = context.createPattern(tile, 'repeat');
  if (!canvasPattern) return backgroundColor;

  canvasPattern.setTransform({ a: 1 / scale, d: 1 / scale });
  cache.set(cacheKey, canvasPattern);
  patternCache.set(context, cache);
  return canvasPattern;
}

function drawDots(context:CanvasRenderingContext2D):void {
  [[2, 2], [6, 6]].forEach(([x, y]) => {
    context.beginPath();
    context.arc(x, y, 1.25, 0, Math.PI * 2);
    context.fill();
  });
}

function drawLines(context:CanvasRenderingContext2D, pattern:number):void {
  context.beginPath();

  if (pattern === 1) {
    context.moveTo(0, PATTERN_SIZE);
    context.lineTo(PATTERN_SIZE, 0);
  } else if (pattern === 2) {
    context.moveTo(0, 0);
    context.lineTo(PATTERN_SIZE, PATTERN_SIZE);
  } else if (pattern === 4) {
    context.moveTo(PATTERN_SIZE / 2, 0);
    context.lineTo(PATTERN_SIZE / 2, PATTERN_SIZE);
    context.moveTo(0, PATTERN_SIZE / 2);
    context.lineTo(PATTERN_SIZE, PATTERN_SIZE / 2);
  }

  context.stroke();
}

const LINE_DASHES = [[], [8, 4], [2, 3], [8, 3, 2, 3], [12, 4]];

export function lineDashFor(index:number):number[] {
  return LINE_DASHES[index % LINE_DASHES.length];
}
