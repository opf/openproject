// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { TestBed, waitForAsync } from '@angular/core/testing';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';

describe('ToastService', () => {
  let toastersService:ToastService;

  beforeEach(waitForAsync(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        OpenprojectHalModule,
      ],
      providers: [
        { provide: ConfigurationService, useValue: { autoHidePopups: () => true } },
        I18nService,
        ToastService,
      ],
    })
      .compileComponents()
      .then(() => {
        toastersService = TestBed.inject(ToastService);
      });
  }));

  it('should be able to create warnings', () => {
    const toaster = toastersService.addWarning('warning!');

    expect(toaster).toEqual({ message: 'warning!', type: 'warning' });
  });

  it('should be able to create error messages with errors', () => {
    const toaster = toastersService.addError('a super cereal error', ['fooo', 'baarr']);
    expect(toaster).toEqual({
      message: 'a super cereal error',
      data: ['fooo', 'baarr'],
      type: 'error',
    });
  });

  it('should be able to create error messages with only a message', () => {
    const toaster = toastersService.addError('a super cereal error');
    expect(toaster).toEqual({
      message: 'a super cereal error',
      data: [],
      type: 'error',
    });
  });

  it('should be able to create upload messages with uploads', () => {
    const toaster = toastersService.addAttachmentUpload('uploading...', [0, 1, 2] as any);
    expect(toaster).toEqual({
      message: 'uploading...',
      type: 'upload',
      data: [0, 1, 2],
    });
  });

  it('should throw an Error if trying to create an upload with uploads = null', () => {
    expect(() => {
      toastersService.addAttachmentUpload('themUploads', null as any);
    }).toThrow();
  });

  it('should throw an Error if trying to create an upload without uploads', () => {
    expect(() => {
      toastersService.addAttachmentUpload('themUploads', []);
    }).toThrow();
  });

  it('sends a broadcast to remove the first toaster upon adding a second success toaster',
    () => {
      const firstToast = toastersService.addSuccess('blubs');
      expect(toastersService.current.value!.length).toEqual(1);

      toastersService.addSuccess('blubs2');
      expect(toastersService.current.value!.length).toEqual(1);
    });

  it('sends a broadcast to remove the first toaster upon adding a second error toaster',
    () => {
      const firstToast = toastersService.addSuccess('blubs');
      toastersService.addError('blubs2');

      expect(toastersService.current.value!.length).toEqual(1);
    });
});
