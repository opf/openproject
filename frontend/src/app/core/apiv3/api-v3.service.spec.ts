//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  TestBed,
  waitForAsync,
} from '@angular/core/testing';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { States } from 'core-app/core/states/states.service';

describe('APIv3Service', () => {
  let service:ApiV3Service;

  beforeEach(waitForAsync(() => {
    void TestBed.configureTestingModule({
      providers: [
        States,
        PathHelperService,
        ApiV3Service,
      ],
    })
      .compileComponents()
      .then(() => {
        service = TestBed.inject(ApiV3Service);
      });
  }));

  function encodeParams(object:any) {
    return new URLSearchParams(object).toString();
  }

  describe('apiV3', () => {
    const projectIdentifier = 'majora';

    it("should provide the project's path", () => {
      expect(service.projects.id(projectIdentifier).path).toEqual('/api/v3/projects/majora');
    });

    it('should provide a path to work package query on subject or ID ', () => {
      let params = {
        filters: '[{"typeahead":{"operator":"**","values":["bogus"]}}]',
        sortBy: '[["updatedAt","desc"]]',
        offset: '1',
        pageSize: '10',
      };

      expect(
        service.work_packages.filterByTypeaheadOrId('bogus').path,
      ).toEqual(`/api/v3/work_packages?${encodeParams(params)}`);

      params = {
        filters: '[{"id":{"operator":"=","values":["1234"]}}]',
        sortBy: '[["updatedAt","desc"]]',
        offset: '1',
        pageSize: '10',
      };
      expect(
        service.work_packages.filterByTypeaheadOrId('1234', true).path,
      ).toEqual(`/api/v3/work_packages?${encodeParams(params)}`);
    });
  });
});
