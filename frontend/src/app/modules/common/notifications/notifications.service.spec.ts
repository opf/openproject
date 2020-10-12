// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {OpenprojectHalModule} from 'core-app/modules/hal/openproject-hal.module';
import {async, TestBed} from '@angular/core/testing';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';

describe('NotificationsService', function () {
  var notificationsService:NotificationsService;

  beforeEach(async(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        OpenprojectHalModule
      ],
      providers: [
        { provide: ConfigurationService, useValue: { autoHidePopups: () => true } },
        I18nService,
        NotificationsService,
      ]
    })
      .compileComponents()
      .then(() => {
        notificationsService = TestBed.get(NotificationsService);
      });
  }));

  it('should be able to create warnings', function () {
    var notification = notificationsService.addWarning('warning!');

    expect(notification).toEqual({message: 'warning!', type: 'warning'});
  });

  it('should be able to create error messages with errors', function () {
    var notification = notificationsService.addError('a super cereal error', ['fooo', 'baarr']);
    expect(notification).toEqual({
      message: 'a super cereal error',
      data: ['fooo', 'baarr'],
      type: 'error'
    });
  });

  it('should be able to create error messages with only a message', function () {
    var notification = notificationsService.addError('a super cereal error');
    expect(notification).toEqual({
      message: 'a super cereal error',
      data: [],
      type: 'error'
    });
  });

  it('should be able to create upload messages with uploads', function () {
    var notification = notificationsService.addAttachmentUpload('uploading...', [0, 1, 2] as any);
    expect(notification).toEqual({
      message: 'uploading...',
      type: 'upload',
      data: [0, 1, 2]
    });
  });

  it('should throw an Error if trying to create an upload with uploads = null', function () {
    expect(function () {
      notificationsService.addAttachmentUpload('themUploads', null as any);
    }).toThrow();
  });

  it('should throw an Error if trying to create an upload without uploads', function () {
    expect(function () {
      notificationsService.addAttachmentUpload('themUploads', []);
    }).toThrow();
  });

  it('sends a broadcast to remove the first notification upon adding a second success notification',
    function () {
      var firstNotification = notificationsService.addSuccess('blubs');
      expect(notificationsService.current.value!.length).toEqual(1);

      notificationsService.addSuccess('blubs2');
      expect(notificationsService.current.value!.length).toEqual(1);
    });

  it('sends a broadcast to remove the first notification upon adding a second error notification',
    function () {
      var firstNotification = notificationsService.addSuccess('blubs');
      notificationsService.addError('blubs2');

      expect(notificationsService.current.value!.length).toEqual(1);
    });
});
