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

import { Component, Type } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridRemoveWidgetService } from 'core-app/shared/components/grids/grid/remove-widget.service';
import { WidgetWpSetMenuComponent } from 'core-app/shared/components/grids/widgets/menu/wp-set-menu.component';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

@Component({ template: '', standalone: true })
class AllowedMenuComponent extends WidgetWpSetMenuComponent {
  protected configurationAllowed() { return Promise.resolve(true); }
}

@Component({ template: '', standalone: true })
class DeniedMenuComponent extends WidgetWpSetMenuComponent {
  protected configurationAllowed() { return Promise.resolve(false); }
}

describe('WidgetWpSetMenuComponent items', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalService, useValue: {} },
        { provide: GridAreaService, useValue: {} },
        { provide: GridRemoveWidgetService, useValue: { registerMenu: () => () => undefined } },
      ],
    });
  });

  const items = (type:Type<WidgetWpSetMenuComponent>):Promise<OpContextMenuItem[]> => (
    TestBed.createComponent(type).componentInstance.menuItemsFactory()
  );

  it('puts Remove widget last, after a divider, in the danger scheme', async () => {
    expect(await items(AllowedMenuComponent)).toEqual([
      expect.objectContaining({ linkText: 'js.toolbar.settings.configure_view' }),
      { divider: true },
      expect.objectContaining({ linkText: 'js.grid.remove', scheme: 'danger' }),
    ]);
  });

  it('offers only Remove widget when configuring is not allowed', async () => {
    expect(await items(DeniedMenuComponent)).toEqual([
      expect.objectContaining({ linkText: 'js.grid.remove', scheme: 'danger' }),
    ]);
  });
});
