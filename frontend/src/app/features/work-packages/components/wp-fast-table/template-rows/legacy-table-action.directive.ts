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

import { DestroyRef, Directive, effect, ElementRef, inject, input, untracked } from '@angular/core';
import { OpTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { removeTabStops } from 'core-app/shared/helpers/dom/remove-tab-stops';

const focusable = 'a, button, input, select, textarea, [tabindex]';

/**
 * Inserts a table action that has no template yet in place of its anchor,
 * taken out of the Tab order like every control of a grid cell.
 */
@Directive({ selector: 'ng-container[opWpLegacyTableAction]' })
export class LegacyTableActionDirective {
  readonly action = input.required<OpTableAction>({ alias: 'opWpLegacyTableAction' });

  private readonly anchor = inject<ElementRef<Comment>>(ElementRef).nativeElement;

  private inserted:ChildNode[] = [];

  constructor() {
    effect(() => {
      const action = this.action();
      untracked(() => this.insert(action));
    });
    inject(DestroyRef).onDestroy(() => this.clear());
  }

  private insert(action:OpTableAction):void {
    this.clear();
    const built = action.buildElement();
    if (!built) return;

    const fragment = document.createDocumentFragment();
    fragment.append(built);
    this.inserted = Array.from(fragment.childNodes);
    this.inserted.forEach((node) => {
      if (!(node instanceof HTMLElement)) return;
      if (node.matches(focusable)) node.setAttribute('tabindex', '-1');
      removeTabStops(node);
    });
    this.anchor.before(fragment);
  }

  private clear():void {
    this.inserted.forEach((node) => node.remove());
    this.inserted = [];
  }
}
