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

import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { OpTableAction } from '../../wp-table/table-actions/table-action';
import { OpDetailsTableAction } from '../../wp-table/table-actions/actions/details-table-action';
import { OpUnlinkTableAction } from '../../wp-table/table-actions/actions/unlink-table-action';
import { LegacyTableActionDirective } from './legacy-table-action.directive';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'span[opWpTableAction]',
  imports: [LegacyTableActionDirective, OpTooltipDirective],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { style: 'display: contents' },
  template: `
    @if (details(); as action) {
      <a
        class="__ui-state-link wp-table--details-link wp-table-context-menu-icon hidden-for-mobile"
        [href]="action.href"
        [attr.data-work-package-id]="action.workPackage.id"
        data-wp-state="split"
        tabindex="-1"
        opTooltip
        [label]="action.label"
      ><i class="icon icon-info2" aria-hidden="true"></i></a>
    } @else if (unlink(); as action) {
      @if (action.applicable(action.workPackage)) {
        <a
          href="#"
          class="wp-table-context-menu-icon wp-table-action--unlink"
          [attr.data-work-package-id]="action.workPackage.id"
          data-wp-table-destructive
          tabindex="-1"
          opTooltip
          [label]="action.title"
          (click)="remove($event, action)"
        ><i class="icon icon-close" aria-hidden="true"></i></a>
      }
    } @else {
      <ng-container [opWpLegacyTableAction]="action()" />
    }
  `,
})
export class WorkPackageTableActionComponent {
  readonly action = input.required<OpTableAction>({ alias: 'opWpTableAction' });
  readonly details = computed(() => {
    const action = this.action();
    return action instanceof OpDetailsTableAction ? action : null;
  });

  readonly unlink = computed(() => {
    const action = this.action();
    return action instanceof OpUnlinkTableAction ? action : null;
  });

  remove(event:MouseEvent, action:OpUnlinkTableAction):void {
    event.preventDefault();
    action.onClick(action.workPackage);
  }
}
