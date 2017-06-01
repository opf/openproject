//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See doc/COPYRIGHT.rdoc for more details.
//++

describe('NotificationsService', function() {
  'use strict';
  var ApiNotificationsService,
      NotificationsService,
      ApiHelper;

  beforeEach(angular.mock.module('openproject.services'));

  beforeEach(inject(function(_ApiNotificationsService_, _NotificationsService_, _ApiHelper_){
    ApiNotificationsService = _ApiNotificationsService_;
    NotificationsService = _NotificationsService_;
    ApiHelper = _ApiHelper_;
  }));

  describe('#addError', function() {
    var error = {},
        messages = [];

    beforeEach(function() {
      sinon.spy(NotificationsService, 'addError');
    });

    describe('with only one error message', function() {
      beforeEach(function() {
        messages = ['Oh my - Error'];
        ApiHelper.getErrorMessages = sinon.stub().returns(messages);
      });

      it('adds the error to the notification service', function() {
        ApiNotificationsService.addError(error);

        expect(NotificationsService.addError).to.have.been.calledWith('Oh my - Error');
      });
    });

    describe('with multiple error messages', function() {
      beforeEach(function() {
        messages = ['Oh my - Error', 'Hey you - Error'];
        ApiHelper.getErrorMessages = sinon.stub().returns(messages);
      });

      it('adds the error to the notification service', function() {
        ApiNotificationsService.addError(error);

        expect(NotificationsService.addError).to.have.been.calledWith('', messages);
      });
    });
  });

  describe('#addSuccess', function() {
    var message = 'Great success';

    beforeEach(function() {
      sinon.spy(NotificationsService, 'addSuccess');
    });

    it('delegates to NotificationService', function() {
      ApiNotificationsService.addSuccess(message);

      expect(NotificationsService.addSuccess).to.have.been.calledWith(message);
    });
  });
});
