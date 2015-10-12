//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

describe.only('flash messages directive', function() {
  var angularCompile, element, scope, timeout, NotificationsService, input;

  beforeEach(angular.mock.module('openproject.uiComponents'));
  beforeEach(angular.mock.module('openproject.services', function($provide) {
    NotificationsService = {
      addSuccess: function() {},
      addError: function() {},
      addWarning: function() {},
      add: function() {}
    };

    $provide.constant('NotificationsService', NotificationsService);
  }));

  beforeEach(inject(function($compile, $rootScope, $timeout) {
    scope = $rootScope.$new();
    angularCompile = $compile;
    timeout = $timeout;
  }));


  var compile = function() {
    element = angular.element(input);

    angularCompile(element)(scope);
    scope.$digest();
    timeout.flush();
  };

  describe('element', function() {
    it('should call the NotificationsService #addSuccess message', function() {
      input = '<flash-messages ng-init="messages = {\'notice\': \'Success\'}"></flash-messages>';
      sinon.spy(NotificationsService, 'addSuccess');

      compile();

      expect(NotificationsService.addSuccess).to.have.been.calledWith('Success');
    });

    it('should call the NotificationsService #addError message', function() {
      input = '<flash-messages ng-init="messages = {\'error\': \'Error\'}"></flash-messages>';
      sinon.spy(NotificationsService, 'addError');

      compile();

      expect(NotificationsService.addError).to.have.been.calledWith('Error');
    });

    it('should call the NotificationsService #addWarning message', function() {
      input = '<flash-messages ng-init="messages = {\'warning\': \'Warning\'}"></flash-messages>';
      sinon.spy(NotificationsService, 'addWarning');

      compile();

      expect(NotificationsService.addWarning).to.have.been.calledWith('Warning');
    });

    it('should fall back to NotificationService #add', function() {
      input = '<flash-messages ng-init="messages = {\'bogus\': \'Bogus\'}"></flash-messages>';
      sinon.spy(NotificationsService, 'add');

      compile();

      expect(NotificationsService.add).to.have.been.calledWith('Bogus');
    });
  });
});
