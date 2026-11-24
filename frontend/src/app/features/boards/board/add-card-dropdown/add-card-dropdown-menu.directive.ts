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

import { Directive, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpActionMenuItems } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-items';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { BoardListComponent } from 'core-app/features/boards/board/board-list/board-list.component';
import {
  AddCardPermission,
  AddCardPermissionsService,
} from 'core-app/features/boards/board/add-card-dropdown/add-card-permissions.service';

const settled = (allowed:boolean):AddCardPermission => ({
  known: allowed,
  current: allowed,
  settle: () => Promise.resolve(),
});

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[op-addCardDropdown]',
})
export class AddCardDropdownMenuDirective extends OpActionMenuItems {
  readonly wpInlineCreate = inject(WorkPackageInlineCreateService);
  readonly boardList = inject(BoardListComponent);
  readonly I18n = inject(I18nService);

  private readonly permissions = inject(AddCardPermissionsService);

  private readonly canAdd = this.permissions.permission('add', () => this.wpInlineCreate.canAdd);

  private readonly canUpdateWorkPackages = this.permissions.permission('reference', () => this.wpInlineCreate.canReference);

  constructor() {
    super();
    void this.canAdd.settle();
    void this.canReference.settle();
  }

  protected buildItems():OpContextMenuItem[]|Promise<OpContextMenuItem[]> {
    const add = this.canAdd;
    const reference = this.canReference;
    if (add.known !== undefined && reference.known !== undefined) {
      return this.itemsFor(add.known, reference.known);
    }
    return Promise
      .all([add.settle(), reference.settle()])
      .then(() => this.itemsFor(add.current, this.canReference.current));
  }

  // A free board only adds the card to the list's order, which saving the
  // query grants; an action board also changes the card.
  private get canReference():AddCardPermission {
    if (this.boardList.board.isAction) {
      return this.canUpdateWorkPackages;
    }
    return settled(!!this.boardList.query?.updateImmediately);
  }

  private itemsFor(canAdd:boolean, canReference:boolean):OpContextMenuItem[] {
    return [
      {
        disabled: !canAdd,
        linkText: this.I18n.t('js.card.add_new'),
        onClick: () => {
          this.boardList.addNewCard();
          return true;
        },
      },
      {
        disabled: !canReference,
        linkText: this.I18n.t('js.relation_buttons.add_existing'),
        onClick: () => {
          this.boardList.addReferenceCard();
          return true;
        },
      },
    ];
  }
}
