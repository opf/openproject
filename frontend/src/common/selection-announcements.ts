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

import { announce } from '@primer/live-region-element';
import type { SelectionKey } from 'core-common/batch-selection';

export type SelectionGesture = 'navigation'|'selection';

export class SelectionAnnouncements {
  private lastKeys:ReadonlySet<SelectionKey> = new Set();

  constructor(private readonly scope:() => string) {}

  get baseline():ReadonlySet<SelectionKey> {
    return this.lastKeys;
  }

  rebase(keys:ReadonlySet<SelectionKey>):void {
    this.lastKeys = keys;
  }

  /**
   * Re-bases to `current` and announces `selected`/`cleared` with `count: current.size`
   * when the gesture rule says so: `navigation` speaks only when it collapsed a batch,
   * `selection` on any membership change. Returns whether it spoke.
   */
  commit(gesture:SelectionGesture, current:ReadonlySet<SelectionKey>, previous:ReadonlySet<SelectionKey> = this.lastKeys):boolean {
    this.lastKeys = current;

    const changed = gesture === 'navigation'
      ? previous.size > 1 && current.size !== previous.size
      : current.size !== previous.size || [...current].some((key) => !previous.has(key));

    if (changed) {
      this.speak(current.size === 0 ? 'cleared' : 'selected', current.size);
    }

    return changed;
  }

  /** Always announces `${scope}.${messageKey}` with `{ count }`. */
  speak(messageKey:string, count:number):void {
    void announce(I18n.t(`${this.scope()}.${messageKey}`, { count }), { politeness: 'polite' });
  }
}
