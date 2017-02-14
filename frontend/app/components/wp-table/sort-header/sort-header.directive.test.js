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

/*jshint expr: true*/

describe('sortHeader Directive', function() {
    var compile, element1, element2, rootScope, scope;

    beforeEach(angular.mock.module('openproject.workPackages.directives'));
    beforeEach(angular.mock.module('openproject.templates', 'openproject.models'));

    beforeEach(inject(function($rootScope, $compile) {
      var header1Html = '<th sort-header sortable="true" query="query" header-name="headerName1" header-title="headerTitle1"></th>';
      var header2Html = '<th sort-header sortable="true" query="query" header-name="headerName2" header-title="headerTitle2"></th>';

      element1 = angular.element(header1Html);
      element2 = angular.element(header2Html);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      var dropdownMenuController = function() {
        this.open = function() {
          return true;
        };
      };

      compile = function() {
        angular.forEach([element1, element2], function(element){
          element.data('$hasDropdownMenuController', dropdownMenuController);
          $compile(element)(scope);
        });

        scope.$digest();
      };
    }));
});
