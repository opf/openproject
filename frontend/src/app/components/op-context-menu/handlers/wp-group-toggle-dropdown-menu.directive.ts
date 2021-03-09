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
import {
  WorkPackageViewDisplayRepresentationService,
  wpDisplayCardRepresentation,
  wpDisplayListRepresentation
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import { WorkPackageViewTimelineService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import { WorkPackageViewCollapsedGroupsService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service";

@Directive({
  selector: '[wpGroupToggleDropdown]'
})
export class WorkPackageGroupToggleDropdownMenuDirective extends OpContextMenuTrigger {
  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly I18n:I18nService,
              readonly wpViewCollapsedGroups:WorkPackageViewCollapsedGroupsService) {
    super(elementRef, opContextMenu);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  public get locals() {
    return {
      items: this.items,
      contextMenuId: 'wp-group-fold-context-menu'
    };
  }

  private buildItems() {
    this.items = [
      {
        disabled: this.wpViewCollapsedGroups.allGroupsAreCollapsed,
        linkText: this.I18n.t('js.button_collapse_all'),
        icon: 'icon-minus2',
        onClick: (evt:JQuery.TriggeredEvent) => {
          this.wpViewCollapsedGroups.setAllGroupsCollapseStateTo(true);

          return true;
        }
      },
      {
        disabled: this.wpViewCollapsedGroups.allGroupsAreExpanded,
        linkText: this.I18n.t('js.button_expand_all'),
        icon: 'icon-plus',
        onClick: (evt:JQuery.TriggeredEvent) => {
          this.wpViewCollapsedGroups.setAllGroupsCollapseStateTo(false);

          return true;
        }
      }
    ];
  }
}

