// -- copyright
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
// ++

describe('Watchers panel directive', function () {
  var $compile, $rootScope, $httpBackend, element;


  beforeEach(angular.mock.module('openproject.services', function($provide) {
    var configurationService = {};

    configurationService.accessibilityModeEnabled = sinon.stub().returns(false);
    $provide.constant('ConfigurationService', configurationService);
  }));
  

  beforeEach(angular.mock.module('openproject.workPackages.controllers', function ($controllerProvider) {
    $controllerProvider.register('WatchersPanelController', function () {});
  }));

  beforeEach(angular.mock.module('openproject.templates'));

  beforeEach(inject(function (_$compile_, _$rootScope_, _$httpBackend_) {
    $compile = _$compile_;
    $rootScope = _$rootScope_;
    $httpBackend = _$httpBackend_;

    $rootScope.workPackage = {
      id: 1234
    };

    $httpBackend.expectGET('/api/v3/work_packages/1234').respond({});
    element = $compile('<watchers-panel work-package="workPackage"></watchers-panel>')($rootScope);
    $rootScope.$digest();
  }));

  it('should should be rendered correctly', function () {
    expect(element.html()).to.contain('detail-panel-watchers');
  });
});
