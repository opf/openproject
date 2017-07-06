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

import {wpDirectivesModule, opTemplatesModule, opConfigModule} from '../../../angular-modules';
import {WorkPackageUploadDirectiveController} from './wp-attachments-upload.directive';
import ICompileService = angular.ICompileService;
import IRootScopeService = angular.IRootScopeService;
import IAugmentedJQuery = angular.IAugmentedJQuery;
import IQService = angular.IQService;
import ICompileProvider = angular.ICompileProvider;

describe('wpAttachmentsUpload directive', () => {
  var $rootScope: IRootScopeService;
  var $q: IQService;
  var html: string;
  var compile: any;
  var element: IAugmentedJQuery;
  var controller: WorkPackageUploadDirectiveController;

  var rootElement: IAugmentedJQuery;

  var workPackage: any;
  var mockMaxSize: number = 123;

  beforeEach(angular.mock.module(
    wpDirectivesModule.name,
    opConfigModule.name,
    opTemplatesModule.name,

    ($compileProvider: ICompileProvider) => {
      $compileProvider.directive('ngfDrop', () => ({
        restrict: 'A',
        scope: {ngfChange: '&', ngModel: '='},

        controller: angular.noop,
        controllerAs: '$ctrl',
        bindToController: true
      }));
    }));
  beforeEach(angular.mock.inject(function (_$rootScope_: IRootScopeService,
                                           _$q_:any,
                                           $compile: ICompileService,
                                           ConfigurationService:any) {
    [$rootScope, $q] = _.toArray(arguments);

    html = `<wp-attachments-upload attachments="attachments" work-package="workPackage">
      </wp-attachments-upload>`;

    workPackage = {
      canAddAttachments: false,
      attachments: {pending: []}
    };

    const scope: any = $rootScope.$new();
    scope.workPackage = workPackage;

    ConfigurationService.api = () => $q.when({maximumAttachmentFileSize: mockMaxSize});

    compile = () => {
      element = $compile(html)(scope);
      scope.$digest();
      controller = element.controller('wpAttachmentsUpload');
      rootElement = element.find('.wp-attachment-upload');
    };

    compile();
  }));

  it('should not be empty', () => {
    expect(element.html()).to.not.be.empty;
  });

  it('should not be rendered', () => {
    expect(rootElement).to.have.length(0);
  });

  it('should have the provided maxFileSize', () => {
    expect(controller.maxFileSize).to.eq(mockMaxSize);
  });

  describe('when it is possible to add attachments to the work package', () => {
    beforeEach(() => {
      workPackage.canAddAttachments = true;
      compile();
    });

    it('should display the directive', () => {
      expect(rootElement).to.have.length(1);
    });

    describe('when clicking the parent element', () => {
      var clicked:any;

      beforeEach(() => {
        clicked = false;
        rootElement.click(() => clicked = true);
        element.click();
      });

      it('should click the first child', () => {
        expect(clicked).to.be.true;
      });
    });
  });
});
