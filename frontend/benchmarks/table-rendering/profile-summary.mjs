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

import { readFile, writeFile } from 'node:fs/promises';
import { TraceMap, originalPositionFor } from '@jridgewell/trace-mapping';

const [profilePath, mapPath, outputPath] = process.argv.slice(2);
if (!profilePath || !mapPath || !outputPath) throw new Error('Usage: node profile-summary.mjs profile.cpuprofile main.js.map summary.json');
const profile = JSON.parse(await readFile(profilePath, 'utf8'));
const map = new TraceMap(JSON.parse(await readFile(mapPath, 'utf8')));
const nodes = new Map(profile.nodes.map((node) => [node.id, node]));
const parents = new Map(profile.nodes.flatMap((node) => (node.children ?? []).map((child) => [child, node.id])));
const locations = new Map(profile.nodes.map(({ id, callFrame }) => {
  const original = callFrame.url.includes('/main-')
    ? originalPositionFor(map, { line: callFrame.lineNumber + 1, column: callFrame.columnNumber })
    : {};
  return [id, { function: callFrame.functionName, source: original.source, line: original.line, name: original.name }];
}));
const totals = new Map();
const self = new Map();
const angularSelf = new Map();
const angularTotals = new Map();
const add = (target, id, time) => target.set(id, (target.get(id) ?? 0) + time);
function addChain(target, chain, time) {
  const seen = new Set();
  for (const id of chain) {
    const key = JSON.stringify(locations.get(id));
    if (seen.has(key)) continue;
    seen.add(key);
    add(target, id, time);
  }
}
for (let index = 0; index < profile.samples.length; index++) {
  const sample = profile.samples[index];
  const time = profile.timeDeltas[index] / 1000;
  const chain = [];
  for (let id = sample; id !== undefined; id = parents.get(id)) chain.push(id);
  const angular = chain.some((id) => nodes.get(id).callFrame.functionName === 'renderRows');
  add(self, sample, time);
  addChain(totals, chain, time);
  if (angular) {
    add(angularSelf, sample, time);
    addChain(angularTotals, chain, time);
  }
}
function report(values) {
  const grouped = new Map();
  for (const [id, ms] of values) {
    const location = locations.get(id);
    const key = JSON.stringify(location);
    grouped.set(key, (grouped.get(key) ?? 0) + ms);
  }
  return [...grouped].map(([key, ms]) => ({ ...JSON.parse(key), ms })).sort((a, b) => b.ms - a.ms);
}
await writeFile(outputPath, JSON.stringify({ self: report(self), total: report(totals), angularSelf: report(angularSelf), angularTotal: report(angularTotals) }, null, 2) + '\n');
console.log(`Saved ${outputPath}`);
