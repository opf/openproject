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

import { DestroyRef, Directive, ElementRef, Injector, Input, inject, viewChild } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { GridRemoveWidgetService, GridWidgetMenu } from 'core-app/shared/components/grids/grid/remove-widget.service';
import {
  IconTriggeredContextMenuComponent,
} from 'core-app/shared/components/op-context-menu/icon-triggered-context-menu/icon-triggered-context-menu.component';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';

@Directive()
export abstract class WidgetAbstractMenuComponent implements GridWidgetMenu {
  readonly injector = inject(Injector);
  readonly i18n = inject(I18nService);
  protected readonly remove = inject(GridRemoveWidgetService);
  protected readonly layout = inject(GridAreaService);
  readonly host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;
  private readonly iconMenu = viewChild(IconTriggeredContextMenuComponent);

  @Input() resource:GridWidgetResource;

  readonly menuItemsFactory = ():Promise<OpContextMenuItem[]> => this.buildItems();

  constructor() {
    inject(DestroyRef).onDestroy(this.remove.registerMenu(this));
  }

  get menuTrigger():HTMLElement|undefined {
    return this.iconMenu()?.trigger;
  }

  protected async buildItems():Promise<OpContextMenuItem[]> {
    return [this.removeItem];
  }

  protected withRemoveLast(items:OpContextMenuItem[]):OpContextMenuItem[] {
    return items.length ? [...items, { divider: true }, this.removeItem] : [this.removeItem];
  }

  protected get removeItem():OpContextMenuItem {
    return {
      linkText: this.i18n.t('js.grid.remove'),
      scheme: 'danger',
      onClick: () => {
        void this.remove.widgetFromMenu(this.resource, this);
        return true;
      },
    };
  }

  public get hasMenu() {
    return this.layout.isEditable;
  }

  public widgetMenuLabel():string {
    return this.i18n.t('js.grid.widget_menu_label', { widgetName: this.resource.options.name });
  }
}
