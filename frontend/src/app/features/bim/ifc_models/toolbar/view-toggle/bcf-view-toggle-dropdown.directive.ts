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
import {
  bcfCardsViewIdentifier,
  bcfSplitViewCardsIdentifier,
  bcfSplitViewTableIdentifier,
  bcfTableViewIdentifier,
  bcfViewerViewIdentifier,
  BcfViewService,
  BcfViewState,
} from 'core-app/features/bim/ifc_models/pages/viewer/bcf-view.service';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { WorkPackageFiltersService } from 'core-app/features/work-packages/components/filters/wp-filters/wp-filters.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

@Directive({
  selector: '[opBcfViewDropdown]',
})
export class BcfViewToggleDropdownDirective extends OpActionMenuItems {
  readonly bcfView = inject(BcfViewService);
  readonly wpFiltersService = inject(WorkPackageFiltersService);
  readonly viewerBridgeService = inject(ViewerBridgeService);

  protected buildItems():OpContextMenuItem[] {
    const keys:BcfViewState[] = this.viewerBridgeService.shouldShowViewer
      ? [bcfViewerViewIdentifier, bcfCardsViewIdentifier, bcfSplitViewCardsIdentifier, bcfSplitViewTableIdentifier, bcfTableViewIdentifier]
      : [bcfCardsViewIdentifier, bcfTableViewIdentifier];
    const current = this.bcfView.currentViewerState();

    return keys.map((key) => ({
      checked: key === current,
      radio: true,
      linkText: this.bcfView.text[key],
      onClick: () => {
        if (key !== current) {
          if (this.wpFiltersService.visible) {
            this.wpFiltersService.toggleVisibility();
          }

          this.bcfView.update(key);
        }

        return true;
      },
    }));
  }
}
