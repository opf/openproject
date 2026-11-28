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
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WpGraphConfigurationService } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration.service';
import { WpGraphConfiguration } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration';
import { defineTestCustomElement, TestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';
import { WorkPackageOverviewGraphComponent } from './wp-overview-graph.component';

describe('WorkPackageOverviewGraphComponent', () => {
  const graphConfigurationStub = {
    configuration: undefined as WpGraphConfiguration|undefined,
    globalScope: false,
    datasets: [],
    reloads: 0,
    reloadQueries() {
      this.reloads += 1;
      return Promise.resolve();
    },
  };
  let custom:TestCustomElement;

  const renderedFilters = () => {
    const [{ props }] = graphConfigurationStub.configuration!.queryParams as { props:{ filters:string } }[];
    return JSON.parse(props.filters) as unknown[];
  };

  beforeEach(async () => {
    graphConfigurationStub.configuration = undefined;
    graphConfigurationStub.globalScope = false;
    graphConfigurationStub.reloads = 0;

    await TestBed.configureTestingModule({
      declarations: [WorkPackageOverviewGraphComponent],
      providers: [{ provide: I18nService, useValue: { t: (key:string) => key } }],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(WorkPackageOverviewGraphComponent, {
        set: {
          template: '',
          providers: [{ provide: WpGraphConfigurationService, useValue: graphConfigurationStub }],
        },
      })
      .compileComponents();
  });

  afterEach(() => custom.element.remove());

  it('queries by the filters from the initial-filters attribute', async () => {
    const filters = [{ version: { operator: '=', values: ['7'] } }];
    custom = await defineTestCustomElement(WorkPackageOverviewGraphComponent, { 'initial-filters': JSON.stringify(filters) });

    expect(renderedFilters()).toEqual(filters);
  });

  it('queries all subprojects without an initial-filters attribute', async () => {
    custom = await defineTestCustomElement(WorkPackageOverviewGraphComponent, {});

    expect(renderedFilters()).toEqual([{ subprojectId: { operator: '*', values: [] } }]);
  });

  it('reads a bare global-scope attribute as true', async () => {
    custom = await defineTestCustomElement(WorkPackageOverviewGraphComponent, { 'global-scope': '' });

    expect(graphConfigurationStub.globalScope).toBe(true);
  });

  it('reads global-scope="false" as false', async () => {
    graphConfigurationStub.globalScope = true;
    custom = await defineTestCustomElement(WorkPackageOverviewGraphComponent, { 'global-scope': 'false' });

    expect(graphConfigurationStub.globalScope).toBe(false);
  });

  it('queries once on init', async () => {
    custom = await defineTestCustomElement(WorkPackageOverviewGraphComponent, {});

    expect(graphConfigurationStub.reloads).toBe(1);
  });

  it('reloads the query when global-scope and initial-filters change', async () => {
    custom = await defineTestCustomElement(WorkPackageOverviewGraphComponent, {});
    const filters = [{ version: { operator: '=', values: ['8'] } }];

    await custom.set('global-scope', '');
    await custom.set('initial-filters', JSON.stringify(filters));

    expect(graphConfigurationStub.globalScope).toBe(true);
    expect(renderedFilters()).toEqual(filters);
    expect(graphConfigurationStub.reloads).toBe(3);
  });

  it('clears the error once a changed input reloads successfully', async () => {
    vi.spyOn(graphConfigurationStub, 'reloadQueries').mockRejectedValueOnce(new Error('failed'));
    const fixture = TestBed.createComponent(WorkPackageOverviewGraphComponent);
    fixture.detectChanges();

    await vi.waitFor(() => expect(fixture.componentInstance.error).toBe('js.chart.errors.could_not_load'));

    fixture.componentRef.setInput('globalScope', true);
    fixture.detectChanges();

    await vi.waitFor(() => expect(fixture.componentInstance.error).toBeNull());
  });
});
