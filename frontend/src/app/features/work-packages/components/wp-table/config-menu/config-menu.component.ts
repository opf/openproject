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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ChangeDetectionStrategy, Component, Injector, inject } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WpTableConfigurationModalComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';

@Component({
  templateUrl: './config-menu.template.html',
  selector: 'wp-table-config-menu',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WorkPackagesTableConfigMenuComponent {
  readonly I18n = inject(I18nService);
  readonly injector = inject(Injector);
  readonly opModalService = inject(OpModalService);
  readonly opContextMenu = inject(OPContextMenuService);

  public text = {
    configureTable: this.I18n.t('js.toolbar.settings.configure_view'),
  };

  public openTableConfigurationModal() {
    this.opContextMenu.close();
    this.opModalService.show(WpTableConfigurationModalComponent, this.injector);
  }
}
