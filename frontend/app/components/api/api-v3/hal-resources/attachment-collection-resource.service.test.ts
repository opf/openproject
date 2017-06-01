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

import {opApiModule, opServicesModule} from '../../../../angular-modules';
import {AttachmentCollectionResource} from './attachment-collection-resource.service';
import {OpenProjectFileUploadService} from '../../op-file-upload/op-file-upload.service';

describe('AttachmentCollectionResource service', () => {
  var AttachmentCollectionResource:any;
  var opFileUpload: OpenProjectFileUploadService;

  beforeEach(angular.mock.module(
    opApiModule.name,
    opServicesModule.name
  ));
  beforeEach(angular.mock.inject(function (_AttachmentCollectionResource_:any,
                                           _opFileUpload_:any) {
    [AttachmentCollectionResource, opFileUpload] = _.toArray(arguments);
  }));

  it('should exist', () => {
    expect(AttachmentCollectionResource).to.exist;
  });

  describe('when creating an attachment collection', () => {
    var collection: AttachmentCollectionResource;

    beforeEach(() => {
      collection = new AttachmentCollectionResource({
        _links: {self: {href: 'attachments'}}
      }, true);
    });

    describe('when using upload()', () => {
      var uploadStub: sinon.SinonStub;
      var params:any;

      beforeEach(() => {
        params = [{}, {}];
        uploadStub = sinon.stub(opFileUpload, 'upload');
        collection.upload((params as any));
      });

      it('should upload the files as expected', () => {
        expect(uploadStub.calledWith(collection.$href, params)).to.be.true;
      });
    });
  });
});
