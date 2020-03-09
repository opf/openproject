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

import { Injector, EventEmitter, Output, Directive } from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {GridRemoveWidgetService} from "core-app/modules/grids/grid/remove-widget.service";
import {OpModalComponent} from "core-components/op-modals/op-modal.component";
import {ComponentType} from '@angular/cdk/portal';
import {WidgetAbstractMenuComponent} from "core-app/modules/grids/widgets/menu/widget-abstract-menu.component";
import {WpGraphConfigurationModalComponent} from "core-app/modules/work-package-graphs/configuration-modal/wp-graph-configuration.modal";
import {GridAreaService} from "core-app/modules/grids/grid/area.service";

@Directive()
export abstract class WidgetWpSetMenuComponent extends WidgetAbstractMenuComponent {
  protected configurationComponent:ComponentType<OpModalComponent>;

  @Output()
  onConfigured:EventEmitter<any> = new EventEmitter();

  protected menuItemList = [
    this.removeItem,
    this.configureItem
  ];

  constructor(private readonly injector:Injector,
              private readonly opModalService:OpModalService,
              readonly i18n:I18nService,
              protected readonly remove:GridRemoveWidgetService,
              readonly layout:GridAreaService) {
  super(i18n,
        remove,
        layout);
  }

  protected get configureItem() {
    return {
      linkText: this.i18n.t('js.toolbar.settings.configure_view'),
      onClick: () => {
        this.opModalService.show(this.configurationComponent, this.injector, this.locals)
          .closingEvent.subscribe((modal:WpGraphConfigurationModalComponent) => {
            this.onConfigured.emit(modal.configuration);
        });
        return true;
      }
    };
  }

  protected get locals() {
    return {};
  }
}
