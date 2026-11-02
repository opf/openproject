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

import { DestroyRef } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { SelectionAnnouncements, type SelectionGesture } from 'core-common/selection-announcements';
import type { SelectionKey } from 'core-common/batch-selection';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import type { WorkPackageTable } from '../../wp-fast-table';

export class TableSelectionFeedback {
  private readonly announcements = new SelectionAnnouncements(() => 'js.work_packages.selection');

  private gestureOwned:ReadonlySet<SelectionKey>|null = null;

  constructor(private readonly selection:WorkPackageViewSelectionService, destroyRef:DestroyRef) {
    this.selection.live$()
      .pipe(takeUntilDestroyed(destroyRef))
      .subscribe(() => {
        if (this.gestureOwned && !sameKeys(this.gestureOwned, this.selection.selectionKeys)) {
          this.gestureOwned = null;
        }
      });
  }

  gesture(kind:SelectionGesture, mutate:() => void):void {
    const before = this.selection.selectionKeys;
    mutate();
    this.announcements.commit(kind, this.selection.selectionKeys, before);
    this.gestureOwned = this.selection.selectionKeys;
  }

  /** Runs `mutate`, re-bases, and always speaks `all_selected` with the new count. */
  selectAll(mutate:() => void):void {
    mutate();
    this.announcements.rebase(this.selection.selectionKeys);
    this.announcements.speak('all_selected', this.selection.selectionCount);
    this.gestureOwned = this.selection.selectionKeys;
  }

  /** Speaks what `retain` pruned only from a membership this table's last gesture produced; otherwise re-bases silently. */
  prune(retain:() => void):void {
    if (this.gestureOwned) {
      this.gesture('selection', retain);
      return;
    }

    retain();
    this.announcements.rebase(this.selection.selectionKeys);
  }
}

function sameKeys(a:ReadonlySet<SelectionKey>, b:ReadonlySet<SelectionKey>):boolean {
  return a.size === b.size && [...a].every((key) => b.has(key));
}

/** Runs `mutate` through the table's feedback when it has one, plainly otherwise. */
export function selectionGesture(table:WorkPackageTable, kind:SelectionGesture, mutate:() => void):void {
  if (table.selectionFeedback) {
    table.selectionFeedback.gesture(kind, mutate);
  } else {
    mutate();
  }
}
