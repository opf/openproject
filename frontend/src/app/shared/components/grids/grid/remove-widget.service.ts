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

import { ChangeDetectorRef, Injectable, Injector, inject } from '@angular/core';
import { GridWidgetArea } from 'core-app/shared/components/grids/areas/grid-widget-area';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { RemovalFocus } from 'core-app/shared/helpers/removal-focus';

export interface GridWidgetMenu {
  readonly host:HTMLElement;
  readonly menuTrigger:HTMLElement|undefined;
}

@Injectable()
export class GridRemoveWidgetService {
  readonly cdRef = inject(ChangeDetectorRef);
  readonly layout = inject(GridAreaService);
  private readonly injector = inject(Injector);
  private readonly menus = new Set<GridWidgetMenu>();
  private addControls:() => readonly HTMLElement[] = () => [];

  public area(area:GridWidgetArea) {
    return this.widget(area.widget);
  }

  public widget(widget:GridWidgetResource):Promise<GridResource> {
    return this.layout
      .removeWidget(widget)
      .finally(() => this.cdRef.detectChanges());
  }

  public registerMenu(menu:GridWidgetMenu):() => void {
    this.menus.add(menu);
    return () => this.menus.delete(menu);
  }

  public registerAddControls(controls:() => readonly HTMLElement[]):void {
    this.addControls = controls;
  }

  public widgetFromMenu(widget:GridWidgetResource, menu:GridWidgetMenu):Promise<void> {
    const focus = new RemovalFocus({
      removed: menu,
      removedElement: menu.host,
      items: () => this.menusInDocumentOrder(),
      control: (item) => item.menuTrigger,
      fallback: () => this.addControls(),
      injector: this.injector,
    });

    return this.widget(widget).then(
      () => focus.focusSuccessorAfterRender(),
      () => focus.cancel(),
    );
  }

  private menusInDocumentOrder():GridWidgetMenu[] {
    return [...this.menus].sort((a, b) => (
      a.host.compareDocumentPosition(b.host) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1
    ));
  }
}
