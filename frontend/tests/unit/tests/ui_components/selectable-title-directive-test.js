//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe('selectableTitle Directive', function() {
  var compile, element, rootScope, scope;

  beforeEach(angular.mock.module(
    'openproject.services',
    'openproject.workPackages',
    'openproject.workPackages.controllers',
    'openproject.templates',
    'truncate'));

  beforeEach(inject(function($rootScope, $compile) {
    var html;
    html = '<selectable-title selected-title="selectedTitle"></selectable-title>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    compile = function() {
      //angular.element(document).find('body').append(element);
      $compile(element)(scope);
      scope.$apply();
    };
  }));

  afterEach(function() {
    element.remove();
  });

  describe('element', function() {
    beforeEach(function() {
      scope.selectedTitle = 'Title1';

      compile();

      scope.$apply();
    });

    it ('displays the title', function() {
      expect(element.find('accessible-by-keyboard').text().replace('\n', '').trim()).to.eq('Title1');
    });
  });
});
