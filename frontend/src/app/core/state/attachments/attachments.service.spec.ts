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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import {
  HttpResponse,
  provideHttpClient,
  withInterceptorsFromDi,
  withXhr,
} from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { firstValueFrom, of } from 'rxjs';
import { States } from 'core-app/core/states/states.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpUploadService } from 'core-app/core/upload/upload.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IAttachment } from 'core-app/core/state/attachments/attachment.model';
import { AttachmentsResourceService } from './attachments.service';

describe('AttachmentsResourceService', () => {
  let service:AttachmentsResourceService;

  const attachment = {
    id: '42',
    fileName: 'a.png',
    _links: {
      self: { href: '/api/v3/attachments/42' },
      delete: { href: '/api/v3/attachments/42' },
    },
  } as unknown as IAttachment;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        AttachmentsResourceService,
        { provide: States, useValue: new States() },
        { provide: ConfigurationService, useValue: {} },
        { provide: I18nService, useValue: { t: () => '' } },
        { provide: ToastService, useValue: { addUpload: vi.fn() } },
        {
          provide: OpUploadService,
          useValue: { upload: vi.fn(() => [of(new HttpResponse({ body: attachment }))]) },
        },
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });

    service = TestBed.inject(AttachmentsResourceService);
  });

  it('initialises via dependency injection', () => {
    expect(service).toBeTruthy();
  });

  describe('attachFiles', () => {
    it('mirrors uploaded attachments into a new resource', async () => {
      const resource = {
        $source: { id: 'new' },
        id: 'new',
        $links: {},
        attachments: { elements: [] },
      } as unknown as HalResource;

      await firstValueFrom(service.attachFiles(resource, [new File([''], 'a.png')]));

      expect(resource.attachments).toEqual({ elements: [{ href: '/api/v3/attachments/42' }] });
    });

    it('leaves the attachments link of a persisted resource untouched', async () => {
      const attachments = { href: '/api/v3/work_packages/5/attachments' };
      const resource = {
        $source: { id: '5' },
        id: '5',
        $links: {},
        attachments,
        addAttachment: { href: '/api/v3/work_packages/5/attachments' },
      } as unknown as HalResource;

      await firstValueFrom(service.attachFiles(resource, [new File([''], 'a.png')]));

      expect(resource.attachments).toBe(attachments);
    });
  });
});
