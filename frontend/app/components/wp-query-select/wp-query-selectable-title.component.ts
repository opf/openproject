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

import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {Component, ElementRef, Inject, Input} from "@angular/core";
import {OpContextMenuTrigger} from "core-components/op-context-menu/handlers/op-context-menu-trigger.directive";
import {WorkPackageQuerySelectDropdownComponent} from "core-components/wp-query-select/wp-query-select-dropdown.component";
import {I18nToken} from "core-app/angular4-transition-utils";

@Component({
  selector: 'wp-query-selectable-title',
  template: require('!!raw-loader!./wp-query-selectable-title.html')
})
export class WorkPackageQuerySelectableTitleComponent extends OpContextMenuTrigger {
  @Input('selectedTitle') public selectedTitle:string;
  public text = {
    search_query_title: this.I18n.t('js.toolbar.search_query_title')
  };

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              @Inject(I18nToken) readonly I18n:op.I18n) {

    super(elementRef, opContextMenu);
  }

  public showDropDown(evt:Event) {
    this.opContextMenu.show(this, evt, WorkPackageQuerySelectDropdownComponent);
  }

  public onOpen(menu:JQuery) {
    menu.find('#query-title-filter').focus();
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(openerEvent:Event) {
    return {
      my: 'left top',
      at: 'left bottom',
      of: this.$element.find('.wp-table--query-menu-link')
    };
  }
}

