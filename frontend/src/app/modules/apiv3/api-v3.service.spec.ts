//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { TestBed, waitForAsync } from "@angular/core/testing";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { States } from "core-components/states.service";

describe('APIv3Service', function() {
  let service:APIV3Service;

  beforeEach(waitForAsync(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      providers: [
        States,
        PathHelperService,
        APIV3Service
      ]
    })
      .compileComponents()
      .then(() => {
        service = TestBed.inject(APIV3Service);
      });
  }));

  function encodeParams(object:any) {
    return new URLSearchParams(object).toString();
  }

  describe('apiV3', function() {
    var projectIdentifier = 'majora';

    it('should provide the project\'s path', function() {
      expect(service.projects.id(projectIdentifier).path).toEqual('/api/v3/projects/majora');
    });

    it('should provide a path to work package query on subject or ID ', function() {
      let params = {
        filters: '[{"subjectOrId":{"operator":"**","values":["bogus"]}}]',
        sortBy: '[["updatedAt","desc"]]',
        offset: '1',
        pageSize: '10'
      };

      expect(
        service.work_packages.filterBySubjectOrId("bogus").path
      ).toEqual('/api/v3/work_packages?' +  encodeParams(params));

      params = {
        filters: '[{"id":{"operator":"=","values":["1234"]}}]',
        sortBy: '[["updatedAt","desc"]]',
        offset: '1',
        pageSize: '10'
      };
      expect(
        service.work_packages.filterBySubjectOrId("1234", true).path
      ).toEqual('/api/v3/work_packages?' +  encodeParams(params));
    });
  });
});
