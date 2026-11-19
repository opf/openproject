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
import { OpActionMenuItems } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-items';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { withOcticon } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-menu-octicons';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[wpGroupToggleDropdown]',
})
export class WorkPackageGroupToggleDropdownMenuDirective extends OpActionMenuItems {
  readonly I18n = inject(I18nService);
  readonly wpViewCollapsedGroups = inject(WorkPackageViewCollapsedGroupsService);

  protected buildItems():OpContextMenuItem[] {
    return [
      {
        disabled: this.wpViewCollapsedGroups.allGroupsAreCollapsed,
        linkText: this.I18n.t('js.button_collapse_all'),
        icon: 'icon-minus2',
        onClick: () => {
          this.wpViewCollapsedGroups.setAllGroupsCollapseStateTo(true);

          return true;
        },
      },
      {
        disabled: this.wpViewCollapsedGroups.allGroupsAreExpanded,
        linkText: this.I18n.t('js.button_expand_all'),
        icon: 'icon-plus',
        onClick: () => {
          this.wpViewCollapsedGroups.setAllGroupsCollapseStateTo(false);

          return true;
        },
      },
    ].map(withOcticon);
  }
}
