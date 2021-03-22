//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { OPContextMenuService } from "core-components/op-context-menu/op-context-menu.service";
import { Directive, ElementRef } from "@angular/core";
import { OpContextMenuTrigger } from "core-components/op-context-menu/handlers/op-context-menu-trigger.directive";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { StateService } from "@uirouter/core";

import { WorkPackageFiltersService } from "core-components/filters/wp-filters/wp-filters.service";
import {
  bimListViewIdentifier, bimSplitViewListIdentifier, bimSplitViewCardsIdentifier, bimTableViewIdentifier,
  bimViewerViewIdentifier,
  BimViewService
} from "core-app/modules/bim/ifc_models/pages/viewer/bim-view.service";
import { ViewerBridgeService } from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import {
  WorkPackageViewDisplayRepresentationService,
  wpDisplayCardRepresentation,
  wpDisplayListRepresentation,
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";

@Directive({
  selector: '[bimViewDropdown]'
})
export class BimViewToggleDropdownDirective extends OpContextMenuTrigger {

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly bimView:BimViewService,
              readonly I18n:I18nService,
              readonly state:StateService,
              readonly wpFiltersService:WorkPackageFiltersService,
              readonly viewerBridgeService:ViewerBridgeService,
              readonly wpDisplayRepresentation:WorkPackageViewDisplayRepresentationService) {

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
    const items = this.viewerBridgeService.shouldShowViewer ?
      [bimViewerViewIdentifier, bimListViewIdentifier, bimSplitViewCardsIdentifier, bimSplitViewListIdentifier, bimTableViewIdentifier] :
      [bimListViewIdentifier, bimTableViewIdentifier];

    this.items = items
      .map(key => {
        return {
          hidden: key === current,
          linkText: this.bimView.text[key],
          icon: this.bimView.icon[key],
          onClick: () => {
            // Close filter section
            if (this.wpFiltersService.visible) {
              this.wpFiltersService.toggleVisibility();
            }

            switch (key) {
            // This project controls the view representation of the data through
            // the wpDisplayRepresentation service that modifies the QuerySpace
            // to inform the rest of the app about which display mode is currently
            // active (this.querySpace.query.live$).
            // Under the hood it is done by modifying the params of actual route.
            // Because of that, it is not possible to call this.state.go and
            // this.wpDisplayRepresentation.setDisplayRepresentation at the same
            // time, it raises a route error (The transition has been superseded by
            // a different transition...). To avoid this error, we are passing
            // a cards params to inform the view about the display representation mode
            // it has to show (cards or list).
            case bimListViewIdentifier:
              this.state.go('bim.partitioned.list', { cards: true });
              break;
            case bimTableViewIdentifier:
              this.state.go('bim.partitioned.list', { cards: false });
              break;
            case bimViewerViewIdentifier:
              this.state.go('bim.partitioned.model');
              break;
            case bimSplitViewCardsIdentifier:
              this.state.go('bim.partitioned.split', { cards: true });
              break;
            case bimSplitViewListIdentifier:
              this.state.go('bim.partitioned.split', { cards: false });
              break;
            }

            return true;
          }
        };
      });
  }
}

