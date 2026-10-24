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

import type { RowPositionEntry } from 'core-app/features/hal/resources/wp-collection-resource';

export interface HierarchyNode {
  readonly id:string;
  /** Visible ancestors, root first. */
  readonly ancestorIds:readonly string[];
}

export function hierarchyOrder(results:readonly HierarchyNode[], positions?:Record<string, RowPositionEntry>):string[] {
  const parents = new Map<string, string|null>();
  const keys = new Map<string, number>();
  results.forEach(({ id, ancestorIds }, rank) => {
    [null, ...ancestorIds, id].forEach((node, index, chain) => {
      if (node === null) return;
      parents.set(node, chain[index - 1] ?? null);
      keys.set(node, Math.min(keys.get(node) ?? rank, rank));
    });
  });

  if (positions && hierarchyAgrees(results, positions)) {
    return [...parents.keys()].sort((a, b) => positions[a].position - positions[b].position);
  }

  const children = new Map<string|null, string[]>();
  [...keys.keys()]
    .sort((a, b) => keys.get(a)! - keys.get(b)!)
    .forEach((id) => {
      const parent = parents.get(id)!;
      children.set(parent, [...(children.get(parent) ?? []), id]);
    });

  const ordered:string[] = [];
  const stack = [...(children.get(null) ?? [])].reverse();
  for (let id = stack.pop(); id !== undefined; id = stack.pop()) {
    ordered.push(id);
    stack.push(...[...(children.get(id) ?? [])].reverse());
  }
  return ordered;
}

/** Whether the collection's parent edges match every edge of the results' visible ancestor chains. */
export function hierarchyAgrees(results:readonly HierarchyNode[], positions:Readonly<Record<string, RowPositionEntry>>):boolean {
  return results.every(({ id, ancestorIds }) => [null, ...ancestorIds, id]
    .every((node, index, chain) => node === null || positions[node]?.parent === (chain[index - 1] ?? null)));
}
