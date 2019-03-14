//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {
  ChangeDetectorRef,
  Directive,
  ElementRef,
  EventEmitter,
  Injector,
  Input,
  OnDestroy,
  OnInit,
  Output
} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {OpContextMenuTrigger} from 'core-components/op-context-menu/handlers/op-context-menu-trigger.directive';
import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {States} from 'core-components/states.service';
import {WorkPackagesListService} from 'core-components/wp-list/wp-list.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {WpTableExportModal} from "core-components/modals/export-modal/wp-table-export.modal";
import {SaveQueryModal} from "core-components/modals/save-modal/save-query.modal";
import {QuerySharingModal} from "core-components/modals/share-modal/query-sharing.modal";
import {WpTableConfigurationModalComponent} from 'core-components/wp-table/configuration-modal/wp-table-configuration.modal';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {
  selectableTitleIdentifier,
  triggerEditingEvent
} from "core-app/modules/common/editable-toolbar-title/editable-toolbar-title.component";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {BoardListComponent} from "core-app/modules/boards/board/board-list/board-list.component";

@Directive({
  selector: '[addCardDropdown]'
})
export class AddCardDropdownMenuDirective extends OpContextMenuTrigger {

  private focusAfterClose = true;

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly opModalService:OpModalService,
              readonly authorisationService:AuthorisationService,
              readonly wpInlineCreate:WorkPackageInlineCreateService,
              readonly boardList:BoardListComponent,
              readonly injector:Injector,
              readonly querySpace:IsolatedQuerySpace,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService) {

    super(elementRef, opContextMenu);
  }

  protected open(evt:JQueryEventObject) {
    this.items = this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(evt:JQueryEventObject) {
    let additionalPositionArgs = {
      my: 'left top',
      at: 'left bottom'
    };

    let position = super.positionArgs(evt);
    _.assign(position, additionalPositionArgs);

    return position;
  }

  private buildItems() {
    return [
      {
        disabled: !this.wpInlineCreate.canAdd,
        linkText: this.I18n.t('js.card.add_new'),
        onClick: () => {
          this.boardList.addNewCard();
          return true;
        }
      },
      {
        disabled: !this.wpInlineCreate.canReference,
        linkText: this.I18n.t('js.relation_buttons.add_existing'),
        onClick: () => {
          this.boardList.addReferenceCard();
          return true;
        }
      }
    ];
  }
}
