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

describe('workPackageGroupSums Directive', function() {
    var compile, element, rootScope, scope;

    beforeEach(angular.mock.module('openproject.workPackages.directives',
                                   'openproject.models',
                                   'openproject.services'));
    beforeEach(module('openproject.api', 'openproject.templates', function($provide) {
      var configurationService = {};

      configurationService.isTimezoneSet = sinon.stub().returns(false);

      $provide.constant('ConfigurationService', configurationService);
    }));

    beforeEach(inject(function($rootScope, $compile) {
      var html;
      html = '<tr work-package-group-sums><td ng-repeat="sum in sums">{{ sum }}</td></tr>';

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('element', function() {
      beforeEach(function() {
        scope.row = {
          groupName: "cheese",
        };
        scope.updateBackUrl = function(){ return 0; };
      });

      describe('setting group sums for the column', function(){
        beforeEach(function(){
          compile();
        });

        it('should render a tr', function() {
          expect(element.prop('tagName')).to.equal('TR');
        });

        it('should set the sums when the group sums change', function() {
          scope.groupSums = [{ ham: 1, cheese: 2, bacon: 3}, { ham: 4, cheese: 5, bacon: 6}];
          scope.$apply();

          var td = element.find('td');
          expect(td.length).to.equal(2);
          expect(td.first().text()).to.equal('2');
          expect(td.first().next().text()).to.equal('5');
        });
      });
    });
});
