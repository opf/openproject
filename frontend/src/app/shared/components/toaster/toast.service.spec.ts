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

import { TestBed, waitForAsync } from '@angular/core/testing';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { Observable, of } from 'rxjs';
import { HttpEvent } from '@angular/common/http';

describe('ToastService', () => {
  let toastService:ToastService;

  beforeEach(waitForAsync(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        OpenprojectHalModule,
        HttpClientTestingModule,
      ],
      providers: [
        { provide: ConfigurationService, useValue: { autoHidePopups: () => true } },
        I18nService,
        ToastService,
      ],
    })
      .compileComponents()
      .then(() => {
        toastService = TestBed.inject(ToastService);
      });
  }));

  it('should be able to create warnings', () => {
    const toaster = toastService.addWarning('warning!');

    expect(toaster).toEqual({ message: 'warning!', type: 'warning' });
  });

  it('should be able to create error messages with errors', () => {
    const toaster = toastService.addError('a super cereal error', ['fooo', 'baarr']);
    expect(toaster).toEqual({
      message: 'a super cereal error',
      data: ['fooo', 'baarr'],
      type: 'error',
    });
  });

  it('should be able to create error messages with only a message', () => {
    const toaster = toastService.addError('a super cereal error');
    expect(toaster).toEqual({
      message: 'a super cereal error',
      data: [],
      type: 'error',
    });
  });

  it('should be able to create upload messages with uploads', () => {
    const uploadData:[File, Observable<HttpEvent<unknown>>][] = [
      [new File([], '1'), of()],
      [new File([], '2'), of()],
      [new File([], '3'), of()],
    ];
    const toaster = toastService.addUpload('uploading...', uploadData);
    expect(toaster).toEqual({
      message: 'uploading...',
      type: 'upload',
      data: uploadData,
    });
  });

  it('should throw an Error if trying to create an upload without uploads', () => {
    expect(() => {
      toastService.addUpload('themUploads', []);
    }).toThrow();
  });

  it('sends a broadcast to remove the first toaster upon adding a second success toaster',
    () => {
      const firstToast = toastService.addSuccess('blubs');
      expect(toastService.current.value!.length).toEqual(1);

      toastService.addSuccess('blubs2');
      expect(toastService.current.value!.length).toEqual(1);
    });

  it('sends a broadcast to remove the first toaster upon adding a second error toaster',
    () => {
      const firstToast = toastService.addSuccess('blubs');
      toastService.addError('blubs2');

      expect(toastService.current.value!.length).toEqual(1);
    });
});
