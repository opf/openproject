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

import {opApiModule} from '../../../angular-modules';
import {OpenProjectFileUploadService, UploadFile} from './op-file-upload.service';
import IRootScopeService = angular.IRootScopeService;

describe('opFileUpload service', () => {
  var $rootScope: IRootScopeService;
  var opFileUpload: OpenProjectFileUploadService;
  var Upload;

  beforeEach(angular.mock.module(opApiModule.name));
  beforeEach(angular.mock.inject(function (_$rootScope_, _opFileUpload_, _Upload_) {
    [$rootScope, opFileUpload, Upload] = _.toArray(arguments);
  }));

  it('should exist', () => {
    expect(opFileUpload).to.exist;
  });

  describe('when uploading multiple files', () => {
    var uploadStub;
    var result;
    const file: any = {
      name: 'name',
      description: 'description'
    };
    const files = [file, file];

    beforeEach(() => {
      uploadStub = sinon.stub(Upload, 'upload');
      result = opFileUpload.upload('somewhere', files);
    });

    afterEach(() => {
      $rootScope.$apply();
      uploadStub.restore();
    });

    it('should call upload once for every file', () => {
      expect(uploadStub.callCount).to.equal(files.length);
    });

    it('should call upload with the correct parameters', () => {
      expect(uploadStub.calledOn({
        file,
        url: 'somewhere',
        fields: {
          metadata: {
            description: file.description,
            fileName: file.name
          }
        }
      }));
    });

    it('should return a resolved promise', () => {
      expect(result).to.eventually.be.fulfilled;
    });
  });
});
