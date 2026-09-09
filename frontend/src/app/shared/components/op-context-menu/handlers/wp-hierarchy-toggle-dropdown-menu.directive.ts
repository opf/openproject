// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2024 the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { Directive, ElementRef } from '@angular/core';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewCollapsedHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-hierarchies.service';

@Directive({
  selector: '[opHierarchyToggleDropdown]',
})
export class WorkPackageHierarchyToggleDropdownMenuDirective extends OpContextMenuTrigger {
  constructor(
    readonly elementRef:ElementRef,
    readonly opContextMenu:OPContextMenuService,
    readonly I18n:I18nService,
    readonly wpViewCollapsedHierarchies:WorkPackageViewCollapsedHierarchiesService,
  ) {
    super(elementRef, opContextMenu);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  public get locals() {
    return {
      items: this.items,
      contextMenuId: 'wp-hierarchy-fold-context-menu',
    };
  }

  private buildItems() {
    this.items = [
      {
        disabled: this.wpViewCollapsedHierarchies.allHierarchiesAreCollapsed,
        linkText: this.I18n.t('js.button_collapse_all'),
        icon: 'icon-minus2',
        onClick: (_evt:JQuery.TriggeredEvent) => {
          this.wpViewCollapsedHierarchies.setAllHierarchiesCollapseStateTo(true);

          return true;
        },
      },
      {
        disabled: this.wpViewCollapsedHierarchies.allHierarchiesAreExpanded,
        linkText: this.I18n.t('js.button_expand_all'),
        icon: 'icon-plus',
        onClick: (_evt:JQuery.TriggeredEvent) => {
          this.wpViewCollapsedHierarchies.setAllHierarchiesCollapseStateTo(false);

          return true;
        },
      },
    ];
  }
}
