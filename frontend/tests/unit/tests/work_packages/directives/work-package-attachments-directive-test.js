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

describe('WorkPackageAttachmentsDirective', function() {
  var compile, element, rootScope, scope, isolatedScope,
      workPackage = {links: {}};

  beforeEach(angular.mock.module('openproject.workPackages.directives'));
  beforeEach(module('openproject.templates'));

  var loadPromise,
      workPackageAttachmentsService = {
        load: function() {
          return loadPromise;
        }
      },
      apiPromise,
      configurationService = {
        api: function() {
          return apiPromise;
        }
      };

  beforeEach(module('openproject.workPackages.services', function($provide) {
    $provide.constant('WorkPackageAttachmentsService', workPackageAttachmentsService);
  }));

  beforeEach(module('openproject.config', function($provide) {
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(inject(function($rootScope, $compile, $q) {
    apiPromise = $q(function(resolve) {
      return resolve('');
    });

    loadPromise = $q(function(resolve) {
      return resolve([]);
    });

    var html = '<work-package-attachments edit work-package="workPackage">' +
               '</work-package-attachments>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    scope.workPackage = workPackage;

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('filterFiles', function() {
    beforeEach(function() {
      compile();
      isolatedScope = element.isolateScope();
    });

    it('filters out attachments of type directory', function() {
      var files = [{type: 'directory'}, {type: 'file'}];

      isolatedScope.filterFiles(files, {}, {}, false);

      expect(files).to.eql([{type: 'file'}]);
    });
  });


  describe('uploadFilteredFiles', function() {
    var files = [{type: 'directory'}, {type: 'file'}],
        dumbPromise = {
          then: function(call) { return call(); }
        };

    beforeEach(function() {
      compile();
      isolatedScope = element.isolateScope();
    });

    it('triggers uploading of non directory files', function() {
      //need to have files to be able to trigger uploads
      isolatedScope.files = files;

      var uploadStub = workPackageAttachmentsService.upload = sinon.stub().returns(dumbPromise);

      isolatedScope.uploadFilteredFiles(files, {}, {}, true);

      expect(uploadStub.calledWith(workPackage, [{type: 'file'}])).to.be.true;
    });
  });
});
