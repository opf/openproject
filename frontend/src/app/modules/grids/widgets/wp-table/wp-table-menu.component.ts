//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {Component, Input, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";
import {WpTableConfigurationModalComponent} from "core-components/wp-table/configuration-modal/wp-table-configuration.modal";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {GridRemoveWidgetService} from "core-app/modules/grids/grid/remove-widget.service";
import {WidgetMenuComponent} from "core-app/modules/grids/widgets/menu/widget-menu.component";

@Component({
  selector: 'widget-wp-table-menu',
  templateUrl: '../menu/widget-menu.component.html',
})
export class WidgetWpTableMenuComponent extends WidgetMenuComponent {
  @Input() resource:GridWidgetResource;

  constructor(private readonly injector:Injector,
              private readonly opModalService:OpModalService,
              readonly i18n:I18nService,
              protected readonly remove:GridRemoveWidgetService) {
    super(i18n,
          remove);
  }

  public get menuItems() {
    return async () => {
      let items:OpContextMenuItem[] = [
        this.removeItem,
        this.configureItem
      ];

      return items;
    };
  }

  protected get configureItem() {
    return {
      linkText: this.i18n.t('js.toolbar.settings.configure_view'),
      onClick: () => {
        this.opModalService.show(WpTableConfigurationModalComponent, this.injector);
        return true;
      }
    };
  }
}
