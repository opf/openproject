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

describe('NotificationBoxDirective', function() {
  var $compile;
  var $rootScope;

  beforeEach(angular.mock.module('openproject.uiComponents', 'openproject.templates'));
  beforeEach(angular.mock.module('openproject.services', function($provide) {
    var configurationService = {};

    configurationService.accessibilityModeEnabled = sinon.stub().returns(false);
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(angular.mock.inject(function(_$compile_, _$rootScope_) {
    $compile = _$compile_;
    $rootScope = _$rootScope_;
  }));

  it('should need a content to properly work', function() {
    expect(function() {
      $compile('<notification-box></notification-box>')($rootScope);
      $rootScope.$digest();
    }).to.throw;
  });

  it('should render with content set', function() {
    $rootScope.warning = { message: 'warning!' };
    var element = $compile('<notification-box content="warning"></notification-box>')($rootScope);
    $rootScope.$digest();
    expect(element.html()).to.contain('warning!');
  });

  it('should render with the appropiate type', function() {
    $rootScope.error = { message: 'error!', type: 'error' };
    var element = $compile('<notification-box content="error"></notification-box>')($rootScope);
    $rootScope.$digest();
    expect(element.html()).to.contain('-error');
  });
});
