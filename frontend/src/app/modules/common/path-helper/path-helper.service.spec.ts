// -- copyright
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
// ++

import {PathHelperService} from './path-helper.service';

describe('PathHelper', function() {
  var PathHelper:PathHelperService = new PathHelperService();

  function encodeParams(object:any) {
    return new URLSearchParams(object).toString();
  }

  describe('apiV3', function() {
    var projectIdentifier = 'majora';

    it('should provide the project\'s path', function() {
      expect(PathHelper.api.v3.projects.id(projectIdentifier).path).toEqual('/api/v3/projects/majora');
    });

    it('should provide a path to the project\'s mentionable principals', function() {
      var projectId = '1';
      var term = 'Maria';

      let params = {
        filters: '[{"status":{"operator":"!","values":["3"]}},{"member":{"operator":"=","values":["1"]}},{"type":{"operator":"=","values":["User","Group"]}},{"id":{"operator":"!","values":["me"]}},{"name":{"operator":"~","values":["Maria"]}}]',
        sortBy: '[["name","asc"]]',
        offset: '1',
        pageSize: '10'
      };

      expect(
        PathHelper.api.v3.principals(projectId, term)
      ).toEqual('/api/v3/principals?' +  encodeParams(params));
    });

    it('should provide a path to work package query on subject or ID ', function() {
      let params = {
        filters: '[{"subjectOrId":{"operator":"**","values":["bogus"]}}]',
        sortBy: '[["updatedAt","desc"]]',
        offset: '1',
        pageSize: '10'
      };

      expect(
        PathHelper.api.v3.wpBySubjectOrId("bogus")
      ).toEqual('/api/v3/work_packages?' +  encodeParams(params));

      params = {
        filters: '[{"id":{"operator":"=","values":["1234"]}}]',
        sortBy: '[["updatedAt","desc"]]',
        offset: '1',
        pageSize: '10'
      };
      expect(
        PathHelper.api.v3.wpBySubjectOrId("1234", true)
      ).toEqual('/api/v3/work_packages?' +  encodeParams(params));
    });
  });
});
