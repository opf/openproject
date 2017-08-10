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

/*jshint expr: true*/

import {CurrentProjectService} from './current-project.service';

describe('currentProject service', function() {
    var element:ng.IAugmentedJQuery;
    var currentProject:CurrentProjectService;

    beforeEach(angular.mock.module('openproject.filters',
                                   'openproject.templates',
                                   'openproject.services'));

    beforeEach(angular.mock.inject((_currentProject_:CurrentProjectService) => {
      currentProject = _currentProject_;
    }));

    describe('with no meta present', () => {
      it('returns null values', () => {
        expect(currentProject.projectId).to.be.null;
        expect(currentProject.projectIdentifier).to.be.null;
        expect(currentProject.apiv3Path).to.be.null;
      });
    });

    describe('with a meta value present', () => {
      beforeEach(() => {
        var html = `
          <meta name="current_project" data-project-id="1" data-project-identifier="foobar"/>
        `;

        element = angular.element(html);
        angular.element(document.body).append(element);
        currentProject.detect();
      });

      afterEach(angular.mock.inject(() => {
        element.remove();
      }));

      it('returns correct values', () => {
        expect(currentProject.projectId).to.eq('1');
        expect(currentProject.projectIdentifier).to.eq('foobar')
        expect(currentProject.apiv3Path).to.eq('/api/v3/projects/1');
      });
    });
});
