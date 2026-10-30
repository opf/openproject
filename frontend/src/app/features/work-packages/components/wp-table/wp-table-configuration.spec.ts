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

import { ChangeDetectorRef, ElementRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { WorkPackageEmbeddedTableEntryComponent } from './embedded/wp-embedded-table-entry.component';
import { WorkPackageTableConfiguration, WorkPackageTableConfigurationObject } from './wp-table-configuration';

import { ExternalQueryConfigurationComponent } from './external-configuration/external-query-configuration.component';
import { OpQueryConfigurationLocalsToken } from './external-configuration/external-query-configuration.constants';
import { UrlParamsHelperService } from '../wp-query/url-params-helper';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';

describe('WorkPackageTableConfiguration', () => {
  it('normalizes omitted options without losing explicit false or custom labels', () => {
    const configuration = new WorkPackageTableConfiguration({
      actionsColumnEnabled: false,
      inlineCreateEnabled: false,
      filterButtonText: 'Refine results',
    });

    expect(configuration.tableVisible).toBe(true);
    expect(configuration.columnMenuEnabled).toBe(true);
    expect(configuration.dragAndDropEnabled).toBe(false);
    expect(configuration.projectIdentifier).toBeNull();
    expect(configuration.actionsColumnEnabled).toBe(false);
    expect(configuration.inlineCreateEnabled).toBe(false);
    expect(configuration.filterButtonText).toBe('Refine results');
  });

  it('retains defaults when a partial input contains undefined fields', () => {
    const configuration = new WorkPackageTableConfiguration({
      tableVisible: undefined,
      projectIdentifier: undefined,
      filterButtonText: undefined,
    });

    expect(configuration.tableVisible).toBe(true);
    expect(configuration.projectIdentifier).toBeNull();
    expect(configuration.filterButtonText).toBe(I18n.t('js.button_filter'));
  });

  it('preserves serialized boolean flags and nullable project context', () => {
    const configuration = new WorkPackageTableConfiguration(JSON.parse(JSON.stringify({
      projectContext: false,
      projectIdentifier: null,
      withFilters: true,
      filterButtonText: '',
    })));

    expect(configuration.projectContext).toBe(false);
    expect(configuration.projectIdentifier).toBeNull();
    expect(configuration.withFilters).toBe(true);
    expect(configuration.filterButtonText).toBe('');
    expect(configuration.contextMenuEnabled).toBe(true);
  });
});

describe('embedded table configuration dataset', () => {
  it.each([null, 'demo-project'])('hydrates serialized configuration with project %s', (projectIdentifier) => {
    const element = document.createElement('wp-embedded-table-entry');
    const provided:WorkPackageTableConfigurationObject = {
      projectContext: false,
      projectIdentifier,
      actionsColumnEnabled: false,
      filterButtonText: 'Refine',
    };
    element.dataset.configuration = JSON.stringify(provided);
    element.dataset.queryProps = JSON.stringify({ columns: ['id', 'subject'] });
    element.dataset.initialLoadingIndicator = 'false';
    TestBed.configureTestingModule({ providers: [{ provide: ElementRef, useValue: new ElementRef(element) }] });

    const entry = TestBed.runInInjectionContext(() => new WorkPackageEmbeddedTableEntryComponent());
    const configuration = new WorkPackageTableConfiguration(entry.configuration);

    expect(entry.configuration).toEqual(provided);
    expect(entry.queryProps).toEqual({ columns: ['id', 'subject'] });
    expect(entry.initialLoadingIndicator).toBe(false);
    expect(configuration.projectIdentifier).toBe(projectIdentifier);
    expect(configuration.actionsColumnEnabled).toBe(false);
    expect(configuration.tableVisible).toBe(true);
    expect(configuration.filterButtonText).toBe('Refine');
  });
});


describe('external query configuration input', () => {
  const request = { 'columns[]': ['id', 'subject'], showHierarchies: false, groupBy: null, filters: '[]' };

  it.each([request, JSON.stringify(request)])('normalizes request parameters %j', (currentQuery) => {
    TestBed.configureTestingModule({ providers: [
      { provide: OpQueryConfigurationLocalsToken, useValue: { currentQuery } },
      { provide: ChangeDetectorRef, useValue: {} },
      { provide: PaginationService, useValue: { getPerPage: () => 20 } },
      UrlParamsHelperService,
    ] });
    const component = TestBed.runInInjectionContext(() => new ExternalQueryConfigurationComponent());
    component.ngOnInit();
    expect(component.queryProps).toEqual(request);
  });

  it.each([{ c: ['id'], hi: false, is: false, g: null, f: [] }, JSON.stringify({ c: ['id'], hi: false, is: false, g: null, f: [] })])(
    'normalizes compact URL parameters %j', (currentQuery) => {
      TestBed.configureTestingModule({ providers: [
        { provide: OpQueryConfigurationLocalsToken, useValue: { currentQuery, urlParams: true } },
        { provide: ChangeDetectorRef, useValue: {} },
        { provide: PaginationService, useValue: { getPerPage: () => 20 } },
        UrlParamsHelperService,
      ] });
      const component = TestBed.runInInjectionContext(() => new ExternalQueryConfigurationComponent());
      component.ngOnInit();
      expect(component.queryProps).toEqual({
        pageSize: 20, 'columns[]': ['id'], showHierarchies: false, includeSubprojects: false,
        groupBy: '', filters: '[]', timelineVisible: undefined,
      });
    },
  );
});
