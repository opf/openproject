//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {OpenProjectFileUploadService, UploadFile, UploadResult} from './op-file-upload.service';
import {HttpClientTestingModule, HttpTestingController} from "@angular/common/http/testing";
import {getTestBed, TestBed} from "@angular/core/testing";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {States} from "core-components/states.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

describe('opFileUpload service', () => {
  let injector:TestBed;
  let service:OpenProjectFileUploadService;
  let httpMock:HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        {provide: States, useValue: new States()},
        I18nService,
        OpenProjectFileUploadService,
        HalResourceService
      ]
    });

    injector = getTestBed();
    service = injector.get(OpenProjectFileUploadService);
    httpMock = injector.get(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  describe('when uploading multiple files', () => {
    var result:UploadResult;
    const file:UploadFile = new File([ JSON.stringify({
        name: 'name',
        description: 'description'
      })], 'name');

    beforeEach(() => {
      result = service.upload('/my/api/path', [file, file]);
      httpMock.match(`/my/api/path`).forEach((req) => {
        expect(req.request.method).toBe("POST");
        req.flush({});
      });
    });

    it('should call upload once for every file, that is no directory', () => {
      expect(result.uploads.length).toEqual(2);
    });

    it('should return a resolved promise that is the summary of the uploads', (done) => {
      result.finished.then(done);
    });
  });
});
