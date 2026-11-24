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

import '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element.js';
import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { ApplicationRef, Component, ComponentRef, ViewContainerRef, viewChild } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { firstValueFrom, Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import 'core-app/shared/components/grids/openproject-grids.module';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridRemoveWidgetService } from 'core-app/shared/components/grids/grid/remove-widget.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { WidgetMenuComponent } from './widget-menu.component';

@Component({
  template: '<ng-container #widgets />',
  providers: [GridRemoveWidgetService],
})
class GridHostComponent {
  readonly widgets = viewChild.required('widgets', { read: ViewContainerRef });
}

describe('WidgetMenuComponent', () => {
  let removeWidget:(widget:GridWidgetResource) => Promise<GridResource>;

  beforeEach(async () => {
    window.I18n.store({
      en: { js: { grid: { remove: 'Remove widget', widget_menu_label: 'Show menu options for %{widgetName} widget' } } },
    });
    await TestBed.configureTestingModule({
      providers: [
        { provide: I18nService, useValue: { t: (key:string, options?:object) => window.I18n.t(key, options) } },
        {
          provide: GridAreaService,
          useValue: { isEditable: true, removeWidget: (widget:GridWidgetResource) => removeWidget(widget) },
        },
      ],
    }).compileComponents();
  });

  describe('alone', () => {
    let fixture:ComponentFixture<WidgetMenuComponent>;

    beforeEach(async () => {
      TestBed.overrideProvider(GridRemoveWidgetService, { useValue: { registerMenu: () => () => undefined } });
      fixture = TestBed.createComponent(WidgetMenuComponent);
      fixture.componentRef.setInput('resource', { options: { name: 'Calendar' } });
      await fixture.whenStable();
    });

    afterEach(() => fixture.destroy());

    it('names its menu button after the widget without showing a tooltip', () => {
      expect(screen.getByRole('button', { name: 'Show menu options for Calendar widget' })).toBeInTheDocument();
      expect(screen.queryByRole('tooltip', { hidden: true })).not.toBeInTheDocument();
    });
  });

  describe('removing a widget from a grid', () => {
    let fixture:ComponentFixture<GridHostComponent>;
    let removal:Subject<GridResource>;
    let removed:Promise<GridResource>;

    beforeEach(async () => {
      removal = new Subject<GridResource>();
      fixture = TestBed.createComponent(GridHostComponent);
      await fixture.whenStable();
      const menus = new Map<object, ComponentRef<WidgetMenuComponent>>();
      ['Calendar', 'News'].forEach((name) => {
        const resource = { options: { name } };
        const menu = fixture.componentInstance.widgets().createComponent(WidgetMenuComponent);
        menu.setInput('resource', resource);
        menus.set(resource, menu);
      });
      removeWidget = (widget) => {
        removed = firstValueFrom(removal).then((grid) => {
          const menu = menus.get(widget);
          menu?.destroy();
          (menu?.location.nativeElement as HTMLElement|undefined)?.remove();
          return grid;
        });
        return removed;
      };
      await fixture.whenStable();

      await userEvent.click(screen.getByRole('button', { name: 'Show menu options for Calendar widget' }));
      const menu = await screen.findByRole('menu', { name: 'Show menu options for Calendar widget' });
      await userEvent.click(within(menu).getByRole('menuitem', { name: 'Remove widget' }));
    });

    afterEach(() => fixture.destroy());

    it('moves focus to the menu button of the next widget', async () => {
      removal.next({} as GridResource);

      await vi.waitFor(() => expect(screen.getByRole('button', { name: 'Show menu options for News widget' })).toHaveFocus());
      expect(screen.queryByRole('button', { name: 'Show menu options for Calendar widget' })).not.toBeInTheDocument();
    });

    it('moves no focus once the grid is gone', async () => {
      const addWidget = document.createElement('button');
      document.body.append(addWidget);
      onTestFinished(() => addWidget.remove());
      fixture.debugElement.injector.get(GridRemoveWidgetService).registerAddControls(() => [addWidget]);
      const focus = vi.spyOn(addWidget, 'focus');

      fixture.destroy();
      removal.next({} as GridResource);
      await removed;
      await TestBed.inject(ApplicationRef).whenStable();

      expect(focus).not.toHaveBeenCalled();
    });
  });
});
