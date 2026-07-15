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

import {
  type Edge,
  attachClosestEdge,
  extractClosestEdge,
} from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import { reorderWithEdge } from '@atlaskit/pragmatic-drag-and-drop-hitbox/util/reorder-with-edge';

export { attachClosestEdge, extractClosestEdge };
export type { Edge };

export type SortableAxis = 'vertical'|'horizontal';

// Reorder a list by item identity using the closest edge of the drop target.
// Indices are resolved from the current list (not carried in the payload) so a
// stale index can never reorder the wrong element. Returns the original list
// (same reference) when either id cannot be found or the move is a no-op, so
// callers can suppress false change events via reference equality.
export function reorderById<T>({
  list,
  getId,
  sourceId,
  targetId,
  closestEdge,
  axis,
}:{
  list:T[];
  getId:(item:T) => string;
  sourceId:string;
  targetId:string;
  closestEdge:Edge|null;
  axis:SortableAxis;
}):T[] {
  const startIndex = list.findIndex((item) => getId(item) === sourceId);
  const indexOfTarget = list.findIndex((item) => getId(item) === targetId);

  if (startIndex === -1 || indexOfTarget === -1) {
    return list;
  }

  const reordered = reorderWithEdge({
    list,
    startIndex,
    indexOfTarget,
    closestEdgeOfTarget: closestEdge,
    axis,
  });

  const isSameOrder = reordered.length === list.length
    && reordered.every((item, index) => item === list[index]);

  return isSameOrder ? list : reordered;
}
