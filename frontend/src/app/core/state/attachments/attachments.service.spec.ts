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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import {
  HttpErrorResponse,
  provideHttpClient,
  withInterceptorsFromDi,
  withXhr,
} from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { firstValueFrom, Observable, throwError } from 'rxjs';
import { States } from 'core-app/core/states/states.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { OpUploadService } from 'core-app/core/upload/upload.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { AttachmentsResourceService } from './attachments.service';

describe('AttachmentsResourceService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        AttachmentsResourceService,
        { provide: States, useValue: new States() },
        { provide: ConfigurationService, useValue: {} },
        { provide: OpUploadService, useValue: {} },
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });
  });

  it('initialises via dependency injection', () => {
    expect(TestBed.inject(AttachmentsResourceService)).toBeTruthy();
  });
});

describe('AttachmentsResourceService upload error handling', () => {
  const halMessage = "The file was rejected by an automatic filter. 'image/webp' is not allowed for upload.";

  function setupWithUploadError(uploadObservable:Observable<never>) {
    TestBed.configureTestingModule({
      imports: [OpenprojectHalModule],
      providers: [
        AttachmentsResourceService,
        { provide: States, useValue: new States() },
        { provide: ConfigurationService, useValue: {} },
        { provide: OpUploadService, useValue: { upload: () => [uploadObservable] } },
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });
  }

  it('re-emits the HAL error message as a plain Error when the upload fails with a HAL error body', async () => {
    const httpError = new HttpErrorResponse({
      status: 422,
      error: {
        _type: 'Error',
        errorIdentifier: 'urn:openproject-org:api:v3:errors:PropertyConstraintViolation',
        message: halMessage,
      },
    });

    setupWithUploadError(throwError(() => httpError));

    const service = TestBed.inject(AttachmentsResourceService);
    vi.spyOn(TestBed.inject(ToastService), 'addUpload').mockReturnValue({ message: '', type: 'upload' });

    await expect(
      firstValueFrom(service.addAttachments('key', '/api/v3/attachments', [{ file: new File([], 'test.webp') }])),
    ).rejects.toThrow(halMessage);
  });

  it('re-emits the raw HTTP message as a plain Error when no HAL body is present', async () => {
    const httpError = new HttpErrorResponse({ status: 500, statusText: 'Internal Server Error' });

    setupWithUploadError(throwError(() => httpError));

    const service = TestBed.inject(AttachmentsResourceService);
    vi.spyOn(TestBed.inject(ToastService), 'addUpload').mockReturnValue({ message: '', type: 'upload' });

    await expect(
      firstValueFrom(service.addAttachments('key', '/api/v3/attachments', [{ file: new File([], 'test.webp') }])),
    ).rejects.toThrow(Error);
  });
});
