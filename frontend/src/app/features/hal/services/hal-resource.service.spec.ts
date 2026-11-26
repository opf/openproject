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
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { firstValueFrom } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { HalError } from './hal-error';
import { HalResourceService } from './hal-resource.service';

describe('HalResourceService requests', () => {
  let service:HalResourceService;
  let http:HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [OpenprojectHalModule],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });
    service = TestBed.inject(HalResourceService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('turns a failed request into a HAL error', async () => {
    const request = firstValueFrom(service.get('/api/v3/statuses/1'));
    http.expectOne('/api/v3/statuses/1').flush({ message: 'Server error' }, { status: 500, statusText: 'Internal Server Error' });

    await expect(request).rejects.toBeInstanceOf(HalError);
  });

  it('keeps an error building the resource from a successful response', async () => {
    const request = firstValueFrom(service.get('/api/v3/statuses/1'));
    http.expectOne('/api/v3/statuses/1').flush({ _type: 'Status', _links: 'invalid' });

    await expect(request).rejects.not.toBeInstanceOf(HalError);
    await expect(request).rejects.toBeInstanceOf(Error);
  });
});
