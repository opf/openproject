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

/*jshint expr: true*/

import {CurrentProjectService} from './current-project.service';
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";

describe('currentProject service', function() {
  let element:JQuery;
  let currentProject:CurrentProjectService;

  beforeEach(() => {
    currentProject = new CurrentProjectService(new PathHelperService());
  });

  describe('with no meta present', () => {
    it('returns null values', () => {
      expect(currentProject.id).toBeNull();
      expect(currentProject.identifier).toBeNull();
      expect(currentProject.name).toBeNull();
      expect(currentProject.apiv3Path).toBeNull();
      expect(currentProject.inProjectContext).toBeFalsy();
    });
  });

  describe('with a meta value present', () => {
    beforeEach(() => {
      let html = `
          <meta name="current_project" data-project-name="Foo 1234" data-project-id="1" data-project-identifier="foobar"/>
        `;

      element = jQuery(html);
      jQuery(document.body).append(element);
      currentProject.detect();
    });

    afterEach((() => {
      element.remove();
    }));

    it('returns correct values', () => {
      expect(currentProject.inProjectContext).toBeTruthy();
      expect(currentProject.id).toEqual('1');
      expect(currentProject.name).toEqual('Foo 1234');
      expect(currentProject.identifier).toEqual('foobar');
      expect(currentProject.apiv3Path).toEqual('/api/v3/projects/1');
    });
  });
});
