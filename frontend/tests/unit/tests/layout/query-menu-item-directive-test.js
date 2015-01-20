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

describe('queryMenuItem Directive', function() {
    var compile, element, rootScope, scope, html;
    var queryId = '25', stateParams = {};

    beforeEach(angular.mock.module('openproject.layout'));
    beforeEach(module('openproject.services', 'openproject.models'));


    beforeEach(module('openproject.templates', function($provide) {
      $provide.value('$stateParams', stateParams);

      var QueryServiceMock = {
        queryName: 'Default',
        updateHighlightName: function() {
          return {
            then: function(callback) {
              return callback();
            }
          };
        },
        unstarQuery: angular.noop
      };
      $provide.value('QueryService', QueryServiceMock);

      // Mock check whether we are on a work_packages page
      $provide.constant('$state', { includes: function() { return true; } });
    }));

    beforeEach(inject(function($rootScope, $compile) {
      html = '<div query-menu-item object-id=' + queryId + '></div>';

      compile = function() {
        element = angular.element(html);
        rootScope = $rootScope;
        scope = $rootScope.$new();
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('when the query id does not match the state param', function() {
      beforeEach(function() {
        stateParams.query_id = '1';

        compile();
        rootScope.$broadcast('openproject.layout.activateMenuItem');
      });

      it('does not add the css-class "selected" to the element', function() {
        expect(element.hasClass('selected')).to.be.false;
      });
    });

    describe('when the query id matches the state param', function() {
      beforeEach(function() {
        stateParams.query_id = queryId;

        compile();
        rootScope.$broadcast('openproject.layout.activateMenuItem');
      });

      it('adds the css-class "selected" to the element', function() {
        expect(element.hasClass('selected')).to.be.true;
      });
    });

    describe('when the query id is undefined', function() {
      beforeEach(function() {
        html = '<div query-menu-item></div>';
      });

      describe('and the state param is null', function() {
        beforeEach(function() {
          stateParams.query_id = null;

          compile();
          rootScope.$broadcast('openproject.layout.activateMenuItem');
        });

        it('adds the css-class "selected" to the element', function() {
          expect(element.hasClass('selected')).to.be.true;
        });
      });

      describe('and the state param is set', function() {
        beforeEach(function() {
          stateParams.query_id = '25';

          compile();
          rootScope.$broadcast('openproject.layout.activateMenuItem');
        });

        it('does not add the css-class "selected" to the element', function() {
          expect(element.hasClass('selected')).to.be.false;
        });
      });
    });

    describe('when the renameQueryMenuItem event is received', function() {
      var queryName = 'A query to find them all';

      beforeEach(function() {
        rootScope.$broadcast('openproject.layout.renameQueryMenuItem', {
          itemType: 'query-menu-item',
          queryid: queryId,
          queryName: queryName
        });
      });

      it('resets the menu item title', function() {
        expect(element.text()).to.equal(queryName);
      });
    });

    describe('when the removeMenuItem event is received', function() {
      var unstar;

      var container = angular.element('<div/>'),
          parent    = angular.element('<li/>');

      beforeEach(inject(function(QueryService) {
        unstar = sinon.stub(QueryService, 'unstarQuery');
      }));

      beforeEach(function() {
        compile();

        container.append(parent);
        parent.append(element);

        rootScope.$broadcast('openproject.layout.removeMenuItem', {
          itemType: 'query-menu-item',
          objectId: queryId,
        });
      });

      it('destroys the menu item', function() {
        expect(container.children()).to.have.length(0);
      });

      it('destroys the menu item scope', function() {
        expect(element.scope()).to.be.undefined;
      });
    });
});
