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

import { Input, Directive } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { OpContextMenuItem } from "core-components/op-context-menu/op-context-menu.types";
import { GridWidgetResource } from "core-app/modules/hal/resources/grid-widget-resource";
import { GridRemoveWidgetService } from "core-app/modules/grids/grid/remove-widget.service";
import { GridAreaService } from "core-app/modules/grids/grid/area.service";

@Directive()
export abstract class WidgetAbstractMenuComponent {
  @Input() resource:GridWidgetResource;

  protected menuItemList:OpContextMenuItem[] = [this.removeItem];

  constructor(readonly i18n:I18nService,
              protected readonly remove:GridRemoveWidgetService,
              protected readonly layout:GridAreaService) {
  }

  public get menuItems() {
    return async () => {
      return this.menuItemList;
    };
  }

  protected get removeItem() {
    return {
      linkText: this.i18n.t('js.grid.remove'),
      onClick: () => {
        this.remove.widget(this.resource);
        return true;
      }
    };
  }

  public get hasMenu() {
    return this.layout.isEditable;
  }
}
