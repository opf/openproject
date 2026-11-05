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

import { Injector } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { WorkPackageTable } from '../../wp-fast-table';
import { selectionGesture, TableSelectionFeedback } from './selection-feedback';
import { registerWorkPackageDeselectAll } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/wp-selection-keyboard';

export class SelectionTransformer {
  @LazyInject() public wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() public wpTableFocus:WorkPackageViewFocusService;

  @LazyInject() public querySpace:IsolatedQuerySpace;

  constructor(public readonly injector:Injector,
    public readonly table:WorkPackageTable) {
    const destroyRef = table.destroyRef;

    const selectionFeedback = new TableSelectionFeedback(this.wpTableSelection, destroyRef);
    table.selectionFeedback = selectionFeedback;

    this.querySpace.tableRendered.values$()
      .pipe(
        takeUntilDestroyed(destroyRef),
      )
      .subscribe((rows) => {
        if (table.ledger.generation > 0) {
          selectionFeedback.prune(() => this.wpTableSelection.retainRendered(rows));
        }
        this.painted = this.currentMarkers();
      });

    this.wpTableSelection.live$()
      .pipe(
        takeUntilDestroyed(destroyRef),
      )
      .subscribe(() => this.paintRows());

    this.wpTableFocus.whenChanged()
      .pipe(
        takeUntilDestroyed(destroyRef),
      )
      .subscribe(() => this.paintRows());

    const unregisterDeselectAll = registerWorkPackageDeselectAll({
      root: table.tableAndTimelineContainer,
      hasState: () => this.wpTableSelection.hasSelectionState,
      clear: () => selectionGesture(table, 'selection', () => this.wpTableSelection.reset()),
    });
    onDestroySafely(destroyRef, unregisterDeselectAll);
  }

  private painted:SelectionMarkers = { selected: new Set(), focused: null };

  /** Repaints the rows whose selection or focus marker changed since the last paint; the render path paints every row, so a render resets the baseline. */
  private paintRows():void {
    if (this.table.ledger.generation === 0) return;
    const current = this.currentMarkers();
    const changed = new Set<string>();
    this.painted.selected.forEach((id) => { if (!current.selected.has(id)) changed.add(id); });
    current.selected.forEach((id) => { if (!this.painted.selected.has(id)) changed.add(id); });
    if (this.painted.focused !== current.focused) {
      [this.painted.focused, current.focused].forEach((id) => { if (id) changed.add(id); });
    }
    this.painted = current;
    const keys = this.table.ledger.keysOfAll(changed);
    if (keys.size === 0) return;
    this.table.mutate(keys.size > this.table.ledger.size / 2 ? 'all' : keys, () => undefined);
  }

  private currentMarkers():SelectionMarkers {
    return {
      selected: new Set(this.wpTableSelection.getSelectedWorkPackageIds()),
      focused: this.wpTableFocus.explicitlyFocusedWorkPackage,
    };
  }
}

interface SelectionMarkers {
  readonly selected:ReadonlySet<string>;
  readonly focused:string|null;
}
