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

describe('NotificationsDirective', function() {
  'use strict';
  var $compile, $rootScope;

  beforeEach(angular.mock.module('openproject.uiComponents'));
  beforeEach(angular.mock.module('openproject.templates')); // see karmaConfig

  beforeEach(angular.mock.module('openproject.services', function($provide) {
    var configurationService = {};

    configurationService.accessibilityModeEnabled = sinon.stub().returns(false);
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(inject(function(_$compile_, _$rootScope_) {
    $compile = _$compile_;
    $rootScope = _$rootScope_;
  }));

  it('should replace the notifications element with the notifications frame', function() {

    var element = $compile('<notifications></notifications>')($rootScope);

    $rootScope.$digest();

    expect(element.html()).to.include('<div class="notification-box--casing">');
  });

  context('w/ notifications present', function() {
    var notification = { message: 'message' };

    it('should be able to receive notification via $broadcast', function() {
      var element = $compile('<notifications></notifications>')($rootScope);
      $rootScope.$digest();
      $rootScope.$broadcast('notification.add', notification);
      expect(element.scope().stack).to.contain(notification);
    });

    it('should remove notifications when called for', function() {
      var element = $compile('<notifications></notifications>')($rootScope);
      $rootScope.$digest();
      expect(element.scope().stack).to.be.empty;
      $rootScope.$broadcast('notification.add', notification);
      expect(element.scope().stack).to.contain(notification);
      $rootScope.$broadcast('notification.remove', notification);
      expect(element.scope().stack).to.be.empty;
    });
  });
});
