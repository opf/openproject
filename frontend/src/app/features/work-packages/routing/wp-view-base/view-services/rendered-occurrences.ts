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

/**
 * Resolves range anchors and Select All anchors against a rendered table or
 * card list.
 *
 * @remarks
 * A work package can be rendered more than once (a normal row, a relation
 * row, an added ancestor). Membership is keyed by work package id; an anchor
 * names one exact rendered occurrence through `classIdentifier`, carried on
 * the shared anchor as `occurrenceKey`. Nothing here touches the DOM or
 * Angular: callers pass the rendered snapshot they hold.
 *
 * @packageDocumentation
 */

import type { SelectionAnchor } from 'core-common/batch-selection';

export function sameOccurrence(a:RenderedWorkPackage, b:RenderedWorkPackage):boolean {
  return a.workPackageId === b.workPackageId && a.classIdentifier === b.classIdentifier;
}

export function selectableOccurrences(rows:readonly RenderedWorkPackage[]):RenderedWorkPackage[] {
  return rows.filter((row) => row.workPackageId !== null);
}

export function anchoredOccurrence(
  rows:readonly RenderedWorkPackage[],
  anchor:SelectionAnchor|null,
):RenderedWorkPackage|undefined {
  if (anchor?.occurrenceKey === undefined) {
    return undefined;
  }

  return rows.find((row) => row.workPackageId === anchor.id && row.classIdentifier === anchor.occurrenceKey);
}

/**
 * Work package ids from the anchored occurrence to `row`, inclusive, in
 * rendered order.
 *
 * @returns `null` when there is no anchor, the anchor is not rendered, or
 *   `row` is not rendered. Hidden rows are included; rows without a work
 *   package (group headers) are skipped.
 */
export function occurrenceRangeIds(
  rows:readonly RenderedWorkPackage[],
  anchor:SelectionAnchor|null,
  row:RenderedWorkPackage,
):string[]|null {
  const anchored = anchoredOccurrence(rows, anchor);
  const start = anchored ? rows.indexOf(anchored) : -1;
  const end = rows.findIndex((candidate) => sameOccurrence(candidate, row));
  if (start < 0 || end < 0) {
    return null;
  }

  return selectableOccurrences(rows.slice(Math.min(start, end), Math.max(start, end) + 1))
    .map((candidate) => candidate.workPackageId!);
}

export function selectAllAnchor(
  selectable:readonly RenderedWorkPackage[],
  requested?:RenderedWorkPackage,
):RenderedWorkPackage|undefined {
  if (requested === undefined) {
    return selectable[0];
  }

  return selectable.find((row) => sameOccurrence(row, requested)) ?? selectable[0];
}
