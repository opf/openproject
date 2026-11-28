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

import { ComponentRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { defineTestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';
import { GlobalSearchWorkPackagesComponent } from './global-search-work-packages.component';

describe('GlobalSearchWorkPackagesComponent as a custom element', () => {
  let filters:{ semanticSearchAvailable:boolean; semanticSearchEnabled:boolean };
  let currentProject:{ id:string|null };

  beforeEach(() => {
    currentProject = { id: null };
    filters = { semanticSearchAvailable: false, semanticSearchEnabled: false };
    TestBed.configureTestingModule({
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: HalResourceService, useValue: {} },
        { provide: WorkPackageViewFiltersService, useValue: filters },
        { provide: IsolatedQuerySpace, useValue: {} },
        { provide: CurrentProjectService, useValue: currentProject },
      ],
    });
    TestBed.overrideComponent(GlobalSearchWorkPackagesComponent, {
      set: { template: '', hostDirectives: [] },
    });
  });

  const instanceOf = (element:HTMLElement) => (
    (element as unknown as { ngElementStrategy:{ componentRef:ComponentRef<GlobalSearchWorkPackagesComponent> } })
      .ngElementStrategy.componentRef.instance
  );

  const filtersOf = (element:HTMLElement) => JSON.parse(instanceOf(element).queryProps.filters!) as unknown[];

  it('builds a text search from the search-term attribute', async () => {
    const custom = await defineTestCustomElement(GlobalSearchWorkPackagesComponent, { 'search-term': 'needle' });

    expect(filtersOf(custom.element)).toEqual([{ search: { operator: '**', values: ['needle'] } }]);
    expect(filters.semanticSearchAvailable).toBe(false);
    expect(filters.semanticSearchEnabled).toBe(false);
  });

  it('restricts to the current project from the scope attribute', async () => {
    const custom = await defineTestCustomElement(GlobalSearchWorkPackagesComponent, {
      'search-term': 'needle',
      scope: 'current_project',
    });

    expect(filtersOf(custom.element)).toContainEqual({ subprojectId: { operator: '!*', values: [] } });
  });

  it('adds no subproject filter in a project without the scope attribute', async () => {
    currentProject.id = '1';
    const custom = await defineTestCustomElement(GlobalSearchWorkPackagesComponent, { 'search-term': 'needle' });

    expect(filtersOf(custom.element)).toEqual([{ search: { operator: '**', values: ['needle'] } }]);
  });

  it('includes subprojects in a project from an empty scope attribute', async () => {
    currentProject.id = '1';
    const custom = await defineTestCustomElement(GlobalSearchWorkPackagesComponent, { 'search-term': 'needle', scope: '' });

    expect(filtersOf(custom.element)).toContainEqual({ subprojectId: { operator: '*', values: [] } });
  });

  it('uses semantic search from the search-mode and bare semantic-search-available attributes', async () => {
    const custom = await defineTestCustomElement(GlobalSearchWorkPackagesComponent, {
      'search-term': 'needle',
      'search-mode': 'semantic',
      'semantic-search-available': '',
    });

    expect(filters.semanticSearchAvailable).toBe(true);
    expect(filters.semanticSearchEnabled).toBe(true);
    expect(filtersOf(custom.element)).toEqual([{ semanticSearch: { operator: '**', values: ['needle'] } }]);
  });

  it('defaults to text mode and unavailable semantic search without the attributes', async () => {
    const custom = await defineTestCustomElement(GlobalSearchWorkPackagesComponent, {});

    expect(instanceOf(custom.element).searchMode()).toBe('text');
    expect(instanceOf(custom.element).semanticSearchAvailable()).toBe(false);
    expect(instanceOf(custom.element).searchTerm()).toBe('');
    expect(instanceOf(custom.element).scope()).toBeUndefined();
  });

  it('restores the defaults when the attributes are removed', async () => {
    const custom = await defineTestCustomElement(GlobalSearchWorkPackagesComponent, {
      'search-mode': 'semantic',
      'semantic-search-available': '',
    });
    await custom.remove('search-mode');
    await custom.remove('semantic-search-available');

    expect(instanceOf(custom.element).searchMode()).toBe('text');
    expect(instanceOf(custom.element).semanticSearchAvailable()).toBe(false);
  });
});
