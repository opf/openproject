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

import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import type { RenderedOccurrence } from '../rendered-occurrence-ledger';
import type { WorkPackageTable } from '../wp-fast-table';
import type { RowKind } from '../handlers/state/keyboard/focus-position';
import { occurrenceRowKind } from './structural-rows';

/** The row's navigation category, or null when the occurrence is excluded from keyboard navigation. */
export function rowKindOf(occurrence:RenderedOccurrence):RowKind|null {
  const kind = occurrenceRowKind(occurrence);
  return kind === 'placeholder' || kind === 'foreign' ? null : kind;
}

export function expansionStateOf(
  table:WorkPackageTable,
  hierarchies:WorkPackageViewHierarchiesService,
  occurrence:RenderedOccurrence,
  kind:RowKind,
):boolean|null {
  if (kind === 'groupHeader') {
    return !table.workPackageViewCollapsedGroupsService.config.state[occurrence.groupIdentifier ?? ''];
  }

  if (kind === 'workPackage' && occurrence.element?.querySelector('.wp-table--hierarchy-indicator')) {
    return !hierarchies.collapsed(occurrence.workPackageId!);
  }

  return null;
}
