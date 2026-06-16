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
import { HttpErrorResponse, provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastComponent } from 'core-app/shared/components/toaster/toast.component';
import { IToast, ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';

describe('ToastComponent', () => {
  let component:ToastComponent;
  let toastService:ToastService;

  const mockToast:IToast = { message: 'Uploading...', type: 'upload' };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OpenprojectHalModule],
      providers: [
        ToastComponent,
        { provide: ConfigurationService, useValue: { autoHidePopups: () => false } },
        I18nService,
        ToastService,
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    }).compileComponents();

    component = TestBed.inject(ToastComponent);
    toastService = TestBed.inject(ToastService);

    component.toast = mockToast;
  });

  describe('#onUploadError', () => {
    it('calls toastService.addError with the HttpErrorResponse', () => {
      const error = new HttpErrorResponse({ status: 422, error: { message: 'image/webp is not allowed' } });
      vi.spyOn(toastService, 'addError').mockReturnValue(null);
      vi.spyOn(toastService, 'remove').mockReturnValue(undefined);

      component.onUploadError(error);

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(toastService.addError).toHaveBeenCalledWith(error);
    });

    it('removes the upload toast after showing the error', () => {
      const error = new HttpErrorResponse({ status: 422, error: { message: 'image/webp is not allowed' } });
      vi.spyOn(toastService, 'addError').mockReturnValue(null);
      vi.spyOn(toastService, 'remove').mockReturnValue(undefined);

      component.onUploadError(error);

      // eslint-disable-next-line @typescript-eslint/unbound-method
      expect(toastService.remove).toHaveBeenCalledWith(mockToast);
    });
  });
});
