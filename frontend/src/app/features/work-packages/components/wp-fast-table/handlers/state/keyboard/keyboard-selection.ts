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

import { isSelectAllShortcut } from 'core-common/selection-shortcuts';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { isSelectableOccurrence, selectableOccurrences } from 'core-app/features/work-packages/routing/wp-view-base/view-services/rendered-occurrences';
import type { WorkPackageTable } from '../../../wp-fast-table';
import { selectionGesture } from '../selection-feedback';
import type { FocusPosition } from './focus-position';

export type SelectionChord = 'toggle'|'extend'|'selectAll';

export function selectionChord(event:KeyboardEvent, applePlatform:boolean):SelectionChord|null {
  if (event.isComposing || event.altKey || event.getModifierState('AltGraph')) {
    return null;
  }

  if (isSelectAllShortcut(event, applePlatform)) {
    return 'selectAll';
  }

  if (!event.shiftKey || event.ctrlKey || event.metaKey) {
    return null;
  }

  switch (event.key) {
    case ' ':
      return 'toggle';
    case 'ArrowUp':
    case 'ArrowDown':
      return 'extend';
    default:
      return null;
  }
}

export class KeyboardSelection {
  constructor(
    private readonly table:WorkPackageTable,
    private readonly selection:WorkPackageViewSelectionService,
  ) {}

  occurrenceAt(position:FocusPosition):RenderedWorkPackage|null {
    const classIdentifier = this.table.ledger.byKey(position.key)?.classIdentifier;
    if (classIdentifier === undefined) {
      return null;
    }

    const rendered = this.table.renderedRows.find((row) => row.classIdentifier === classIdentifier);
    return rendered && isSelectableOccurrence(rendered) ? rendered : null;
  }

  toggle(position:FocusPosition):boolean {
    const occurrence = this.occurrenceAt(position);
    if (!occurrence) {
      return false;
    }

    selectionGesture(this.table, 'selection', () => this.selection.toggleOccurrence(occurrence));
    return true;
  }

  extendTo(arrived:FocusPosition):void {
    const occurrence = this.occurrenceAt(arrived);
    if (occurrence) {
      selectionGesture(this.table, 'selection', () => this.selection.rangeTo(occurrence, this.table.renderedRows));
    }
  }

  selectAll(position:FocusPosition):boolean {
    const rows = this.table.renderedRows;
    if (selectableOccurrences(rows).length === 0) {
      return false;
    }

    const select = () => this.selection.selectAll(rows, this.occurrenceAt(position));
    if (this.table.selectionFeedback) {
      this.table.selectionFeedback.selectAll(select);
    } else {
      select();
    }
    return true;
  }
}
