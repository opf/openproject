//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {Directive, ElementRef} from "@angular/core";
import {OpContextMenuTrigger} from "core-components/op-context-menu/handlers/op-context-menu-trigger.directive";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {
  bimListViewIdentifier,
  bimSplitViewIdentifier,
  bimViewerViewIdentifier
} from "core-app/modules/ifc_models/view-toggle/bim-view-toggle.component";
import {StateService} from "@uirouter/core";
import {BimViewService} from "core-app/modules/ifc_models/view-toggle/bim-view.service";

@Directive({
  selector: '[bimViewDropdown]'
})
export class BimViewToggleDropdownDirective extends OpContextMenuTrigger {
  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly bimView:BimViewService,
              readonly I18n:I18nService,
              readonly state:StateService) {

    super(elementRef, opContextMenu);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  public get locals() {
    return {
      items: this.items,
      contextMenuId: 'bim-view-context-menu'
    };
  }

  private buildItems() {
    const current = this.bimView.current;
    const viewRoute = this.state.current.data.viewRoute;

    this.items = [bimViewerViewIdentifier, bimListViewIdentifier, bimSplitViewIdentifier]
      .map(key => {
        return {
          hidden: key === current,
          linkText: this.bimView.text[key],
          onClick: () => {
            switch (key) {
              case bimListViewIdentifier:
                this.state.go('bim.space.list');
                break;
              case bimViewerViewIdentifier:
                this.state.go(viewRoute + '.model');
                break;
              case bimSplitViewIdentifier:
                this.state.go(viewRoute);
                break;
            }

            return true;
          }
        };
      });
  }
}

