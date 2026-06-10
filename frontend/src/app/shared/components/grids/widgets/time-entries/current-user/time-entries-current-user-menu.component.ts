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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy, Component, EventEmitter, Output, inject,
} from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  WidgetAbstractMenuComponent,
} from 'core-app/shared/components/grids/widgets/menu/widget-abstract-menu.component';
import {
  TimeEntriesCurrentUserConfigurationModalComponent,
} from 'core-app/shared/components/grids/widgets/time-entries/current-user/configuration-modal/configuration.modal';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

@Component({
  selector: 'widget-time-entries-current-user-menu',
  templateUrl: '../../menu/widget-menu.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class WidgetTimeEntriesCurrentUserMenuComponent extends WidgetAbstractMenuComponent {
  readonly opModalService = inject(OpModalService);

  @Output() onConfigured = new EventEmitter<any>();

  protected async buildItems():Promise<OpContextMenuItem[]> {
    return [
      this.removeItem,
      this.configureItem,
    ];
  }

  protected get configureItem() {
    return {
      linkText: this.i18n.t('js.grid.configure'),
      onClick: () => {
        this.opModalService.show(TimeEntriesCurrentUserConfigurationModalComponent, this.injector, this.locals)
          .subscribe(
            (modal) => modal.closingEvent.subscribe(() => {
              if (modal.options) {
                this.onConfigured.emit(modal.options);
              }
            }),
          );
        return true;
      },
    };
  }

  protected get locals() {
    return { options: this.resource.options };
  }
}
