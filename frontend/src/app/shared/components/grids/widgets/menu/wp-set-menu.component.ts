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

import { Directive, EventEmitter, Output } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { ComponentType } from '@angular/cdk/portal';
import {
  WidgetAbstractMenuComponent,
} from 'core-app/shared/components/grids/widgets/menu/widget-abstract-menu.component';
import {
  WpGraphConfigurationModalComponent,
} from 'core-app/shared/components/work-package-graphs/configuration-modal/wp-graph-configuration.modal';
import {
  WpTableConfigurationModalComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

@Directive()
export abstract class WidgetWpSetMenuComponent extends WidgetAbstractMenuComponent {
  protected configurationComponent:ComponentType<WpGraphConfigurationModalComponent | WpTableConfigurationModalComponent>;

  @InjectField() opModalService:OpModalService;

  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  @Output() onConfigured:EventEmitter<unknown> = new EventEmitter();

  protected async buildItems():Promise<OpContextMenuItem[]> {
    const items = [
      this.removeItem,
    ];

    if (await this.configurationAllowed()) {
      items.push(this.configureItem);
    }

    return items;
  }

  protected get configureItem() {
    return {
      linkText: this.i18n.t('js.toolbar.settings.configure_view'),
      onClick: () => {
        this.opModalService
          .show(this.configurationComponent, this.injector, this.locals)
          .subscribe((modal) => modal.closingEvent.subscribe(() => {
            if (modal instanceof WpGraphConfigurationModalComponent) {
              this.onConfigured.emit(modal.configuration);
            }
          }));
        return true;
      },
    };
  }

  protected configurationAllowed():Promise<boolean> {
    return Promise.resolve(true);
  }

  protected get locals() {
    return {};
  }
}
