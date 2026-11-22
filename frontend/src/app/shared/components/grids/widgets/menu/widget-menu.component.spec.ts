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
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import 'core-app/shared/components/grids/openproject-grids.module';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridRemoveWidgetService } from 'core-app/shared/components/grids/grid/remove-widget.service';
import { WidgetMenuComponent } from './widget-menu.component';

describe('WidgetMenuComponent', () => {
  let fixture:ComponentFixture<WidgetMenuComponent>;

  beforeEach(async () => {
    window.I18n.store({ en: { js: { grid: { widget_menu_label: 'Show menu options for %{widgetName} widget' } } } });
    await TestBed.configureTestingModule({
      providers: [
        { provide: I18nService, useValue: { t: (key:string, options?:object) => window.I18n.t(key, options) } },
        { provide: GridAreaService, useValue: { isEditable: true } },
        { provide: GridRemoveWidgetService, useValue: {} },
      ],
    }).compileComponents();

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
