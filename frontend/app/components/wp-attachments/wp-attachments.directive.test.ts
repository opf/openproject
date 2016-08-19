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

import {WorkPackageAttachmentsController} from './wp-attachments.directive';
import {
  openprojectModule, wpDirectivesModule, opTemplatesModule,
  wpServicesModule, opConfigModule
} from '../../angular-modules';
import IQService = angular.IQService;

describe('wpAttachments directive', () => {
  var $q:IQService;
  var files;
  var controller:WorkPackageAttachmentsController;
  var workPackage = {};

  beforeEach(angular.mock.module(
    openprojectModule.name,
    wpDirectivesModule.name,
    opTemplatesModule.name
  ));

  var loadPromise;
  var apiPromise;

  beforeEach(angular.mock.inject(function ($rootScope, $compile, $httpBackend, _$q_) {
    $q = _$q_;

    files = [{type: 'directory'}, {type: 'file'}];
    apiPromise = $q.when('');
    loadPromise = $q.when([]);

    // Skip the work package cache update
    $httpBackend.expectGET('/api/v3/work_packages/1234').respond(200, {});

    const element = angular.element('<wp-attachments work-package="workPackage"></wp-attachments>');
    const scope = $rootScope.$new();

    scope.workPackage = workPackage;

    $compile(element)(scope);
    scope.$digest();
    element.isolateScope();

    controller = element.controller('wpAttachments');
  }));
});
