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

import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DashboardComponent } from 'core-app/features/overview/dashboard.component';
import { GridInitializationService } from 'core-app/shared/components/grids/grid/initialization.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { GridAddWidgetService } from 'core-app/shared/components/grids/grid/add-widget.service';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { defineTestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';

describe('DashboardComponent as a custom element', () => {
  const initialize = vi.fn();

  beforeEach(async () => {
    initialize.mockReset().mockReturnValue(of());
    TestBed.overrideComponent(DashboardComponent, {
      set: { template: '', templateUrl: undefined, styleUrls: [], imports: [], providers: [] },
    });
    await TestBed.configureTestingModule({
      providers: [
        { provide: GridAddWidgetService, useValue: {} },
        { provide: GridAreaService, useValue: {} },
        { provide: CurrentProjectService, useValue: {} },
        { provide: ConfigurationService, useValue: {} },
        { provide: GridInitializationService, useValue: { initialize } },
        { provide: PathHelperService, useValue: { projectDashboardsPath: (id:string) => `/projects/${id}/dashboards` } },
      ],
    }).compileComponents();
  });

  it('scopes the grid to the project identifier attribute', async () => {
    await defineTestCustomElement(DashboardComponent, { 'project-identifier': 'acme' });

    expect(initialize).toHaveBeenCalledWith('/projects/acme/dashboards');
  });
});
