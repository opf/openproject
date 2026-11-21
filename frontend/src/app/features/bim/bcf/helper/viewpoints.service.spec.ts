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
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { firstValueFrom } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ViewpointsService } from './viewpoints.service';

describe('ViewpointsService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [OpenprojectHalModule],
      providers: [
        ViewpointsService,
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });
  });

  it('sets no BCF topic without the permission to manage BCF', async () => {
    const workPackage = TestBed.inject(HalResourceService)
      .createHalResource<WorkPackageResource>({ _type: 'WorkPackage', id: '42', _links: {} });

    const topic = await firstValueFrom(TestBed.inject(ViewpointsService).setBcfTopic$(workPackage), { defaultValue: 'none' });

    expect(topic).toBe('none');
  });
});
