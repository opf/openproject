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
import SinonStub = Sinon.SinonStub;
import IQService = angular.IQService;
import ICompileProvider = angular.ICompileProvider;

describe('wpAttachmentsUpload directive', () => {
  var $rootScope: IRootScopeService;
  var $q: IQService;
  var compile: any;
  var element: IAugmentedJQuery;
  var controller: WorkPackageUploadDirectiveController;

  var wrapperElement: IAugmentedJQuery;

  var workPackage: any;
  var uploadAttachments: SinonStub;
  var mockMaxSize: number = 123;

  beforeEach(angular.mock.module(
    wpDirectivesModule.name,
    opConfigModule.name,
    opTemplatesModule.name,

    ($compileProvider: ICompileProvider) => {
      $compileProvider.directive('ngfDrop', () => ({
        restrict: 'A',
        scope: {ngfChange: '&'},

        controller: angular.noop,
        controllerAs: '$ctrl',
        bindToController: true
      }));
    }));
  beforeEach(angular.mock.inject(function (_$rootScope_: IRootScopeService,
                                           _$q_,
                                           $compile: ICompileService,
                                           ConfigurationService) {
    [$rootScope, $q] = _.toArray(arguments);

    const html =
      `<wp-attachments-upload
          attachments="attachments"
          work-package="workPackage"></wp-attachments-upload>`;

    uploadAttachments = sinon.stub().returns($q.when());
    workPackage = {uploadAttachments};

    const scope: any = $rootScope.$new();
    scope.workPackage = workPackage;
    scope.attachments = [];

    workPackage.uploadAttachments = uploadAttachments;

    ConfigurationService.api = () => $q.when({maximumAttachmentFileSize: mockMaxSize});

    compile = () => {
      element = $compile(html)(scope);
      $rootScope.$apply();
      controller = element.controller('wpAttachmentsUpload');
      wrapperElement = element.find('.work-package--attachments--drop-box');
    };

    compile();
  }));

  it('should not be empty', () => {
    expect(element.html()).to.not.be.empty;
  });

  it('should not be rendered', () => {
    expect(wrapperElement).to.have.length(0);
  });

  it('should have the provided maxFileSize', () => {
    expect(controller.maxFileSize).to.eq(mockMaxSize);
  });

  const testDirectiveIsDisplayed = () => {
    it('should display the directive', () => {
      expect(wrapperElement).to.have.length(1);
    });
  };

  const testCanUploadIsTrue = prepare => {
    beforeEach(() => {
      prepare();
      compile();
    });

    testDirectiveIsDisplayed();

    it('should set the controller property `canUpload` to true', () => {
      expect(controller.canUpload).to.be.true;
    });

    it('should set the max size property of the element to the configured value', () => {
      expect(wrapperElement.attr('ngf-max-size')).to.equal(mockMaxSize.toString());
    });
  };

  const testFileUpload = additional => {
    describe('when uploading files', () => {
      var file;
      var directory;
      var files;
      var filtered;

      beforeEach(() => {
        file = {type: 'file'};
        directory = {type: 'directory'};
        files = [file, directory];
        filtered = [file];
        controller.files = files;

        const ngfController: any = wrapperElement.controller('ngfDrop');
        ngfController.ngfChange();
      });

      it('should remove files of type `directory`', () => {
        expect(controller.files).to.have.members(filtered);
      });

      additional();
    });
  };

  describe('when the work package has an `addAttachment` property', () => {
    testCanUploadIsTrue(() => {
      workPackage.addAttachment = true;
    });

    testFileUpload(() => {
      it('should have called uploadAttachments() with the given files', () => {
        expect(uploadAttachments.calledWith(controller.files)).to.be.true;
      });

      it('should reset the files array', () => {
        $rootScope.$apply();
        expect(controller.files).to.have.length(0);
      });
    });
  });

  describe('when the work package is new', () => {
    testCanUploadIsTrue(() => {
      workPackage.isNew = true;
    });

    testFileUpload(() => {
      it('should have updated the attachments property of the controller', () => {
        expect(controller.attachments).to.have.members(controller.files);
      });

      it('should not have called the uploadAttachments method of the work package', () => {
        expect(uploadAttachments.called).to.be.false;
      });
    });
  });
});
