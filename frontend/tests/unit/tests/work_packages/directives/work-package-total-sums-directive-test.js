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

describe('workPackageTotalSums Directive', function() {
    var compile, element, rootScope, scope, stateParams = {};

    beforeEach(angular.mock.module('openproject.workPackages.directives',
                                   'openproject.models',
                                   'openproject.layout',
                                   'openproject.services'));

    beforeEach(module('openproject.api', 'openproject.templates', function($provide) {
      var configurationService = {};

      configurationService.isTimezoneSet = sinon.stub().returns(false);

      $provide.constant('$stateParams', stateParams);
      $provide.constant('ConfigurationService', configurationService);
    }));

    beforeEach(inject(function($rootScope, $compile) {
      var html;
      html = '<tr work-package-total-sums><td ng-repeat="column in columns">{{ column["total_sum"] }}</td></tr>';

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('element', function() {
      beforeEach(inject(function($q) {
        scope.query = Factory.build('Query', {
          id: null,
          columns: [{ name: 'cheese', total_sum: 1 }]
        });
        scope.columns = scope.query.columns;
      }));
      beforeEach(function(){
        compile();
      });

      it('should render a tr', function() {
        expect(element.prop('tagName')).to.equal('TR');
      });

      it('should set the sums', function() {
        var td = element.find('td');
        expect(td.length).to.equal(1);
        expect(td.first().text()).to.equal('1');
      });

      describe('setting total sums for the columns', function(){
        beforeEach(inject(function($q, WorkPackageService) {
          var sumsData = [1, 2];

          scope.updateBackUrl = function(){ return 0; };

          WorkPackageService.getWorkPackagesSums = function() {
            var deferred = $q.defer();
            deferred.resolve({ column_sums: sumsData } );
            return deferred.promise;
          };
        }));

        it('should fetch the sums when the columns change', function() {
          scope.columns = [{ name: 'cheese' }, { name: 'toasties' }];
          scope.$apply();

          var td = element.find('td');
          expect(td.length).to.equal(2);
          expect(td.first().text()).to.equal('1');
          expect(td.first().next().text()).to.equal('2');
        });
      });
    });
});
