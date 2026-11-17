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

import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { Component, input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { screen } from '@testing-library/dom';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageOverviewTabComponent } from './overview-tab.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector -- Matches the production child.
  selector: 'wp-single-view',
  template: '<h2>{{ workPackage().subject }}</h2>',
})
class SingleViewStubComponent {
  readonly workPackage = input.required<WorkPackageResource>();
}

describe('WorkPackageOverviewTabComponent', () => {
  let api:ApiV3Service;
  let hal:HalResourceService;
  let http:HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SingleViewStubComponent],
      declarations: [WorkPackageOverviewTabComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        SchemaCacheService,
        States,
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    }).compileComponents();
    api = TestBed.inject(ApiV3Service);
    hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', { cls: WorkPackageResource });
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  function source(id:number, subject:string) {
    return { _type: 'WorkPackage', subject, _links: { self: { href: `/api/v3/work_packages/${id}` } } };
  }

  function workPackage(id:number, subject:string) {
    return hal.createHalResource<WorkPackageResource>(source(id, subject));
  }

  it('loads the current work package and forwards cache updates to the single view', async () => {
    const fixture = TestBed.createComponent(WorkPackageOverviewTabComponent);
    fixture.componentRef.setInput('workPackage', workPackage(1, 'Original subject'));
    await fixture.whenStable();
    expect(screen.getByRole('heading', { name: 'Original subject' })).toBeInTheDocument();

    http.expectOne('/api/v3/work_packages/1').flush(source(1, 'Loaded subject'));
    expect(await screen.findByRole('heading', { name: 'Loaded subject' })).toBeInTheDocument();

    await api.work_packages.cache.updateWorkPackage(workPackage(1, 'Updated subject'));
    expect(await screen.findByRole('heading', { name: 'Updated subject' })).toBeInTheDocument();
  });

  it('forwards the replacement work package stream and stops listening to the previous one', async () => {
    const first = workPackage(1, 'Original subject');
    const second = workPackage(2, 'Replacement subject');
    await api.work_packages.cache.updateWorkPackage(first);
    await api.work_packages.cache.updateWorkPackage(second);
    const fixture = TestBed.createComponent(WorkPackageOverviewTabComponent);
    fixture.componentRef.setInput('workPackage', first);
    await fixture.whenStable();
    expect(screen.getByRole('heading', { name: 'Original subject' })).toBeInTheDocument();

    fixture.componentRef.setInput('workPackage', second);
    expect(await screen.findByRole('heading', { name: 'Replacement subject' })).toBeInTheDocument();

    await api.work_packages.cache.updateWorkPackage(workPackage(1, 'Old update'));
    await fixture.whenStable();
    expect(screen.getByRole('heading', { name: 'Replacement subject' })).toBeInTheDocument();

    await api.work_packages.cache.updateWorkPackage(workPackage(2, 'New update'));
    expect(await screen.findByRole('heading', { name: 'New update' })).toBeInTheDocument();
  });
});
