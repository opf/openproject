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

import {WorkPackageQuerySelectController} from './wp-query-select.controller'

describe('Work package query select', function() {
  var container:any, contextMenu:any, $rootScope:any, scope:any, ngContextMenu:any, queriesPromise:any, I18n:any;

  beforeEach(angular.mock.module('ng-context-menu',
                    'openproject.workPackages',
                    'openproject.workPackages.controllers',
                    'openproject.models',
                    'openproject.api',
                    'openproject.layout',
                    'openproject.templates'));

  beforeEach(angular.mock.module('openproject.api', ($provide:ng.auto.IProvideService) => {
    var queryDm = {
      all: () => queriesPromise
    };

    $provide.constant('QueryDm', queryDm);
  }));

  beforeEach(function() {
    var html = '<div></div>';
    container = angular.element(html);
  })

  beforeEach(inject(function(_$rootScope_:any, _ngContextMenu_:any, $q:ng.IQService, $templateCache:any, _I18n_:any) {
    $rootScope = _$rootScope_;
    ngContextMenu = _ngContextMenu_;
    I18n = _I18n_;

    var template = $templateCache.get('/components/wp-query-select/wp-query-select.template.html');

    $templateCache.put('template.html', [200, template, {}]);

    var queries = {
      elements: [
        {
          name: 'firstQuery',
          $href: 'api/firstQuery',
          public: true,
        },
        {
          name: 'secondQuery',
          $href: 'api/secondQuery',
          public: false
        }
      ]
    }

    sinon.stub(_I18n_, 't')
         .withArgs('js.label_global_queries')
         .returns('Public Queries')
         .withArgs('js.label_custom_queries')
         .returns('Private Queries');

    var deferred = $q.defer()
    deferred.resolve(queries);

    queriesPromise = deferred.promise;

    contextMenu = ngContextMenu({
      controller: WorkPackageQuerySelectController,
      container: container,
      templateUrl: 'template.html'
    });

    contextMenu.open({x: 0, y: 0});
  }));

  beforeEach(function() {
    // for jQuery to work, we need to append the element
    // to the dom
    container.appendTo(document.body);
    $rootScope.$digest();

    scope = container.children().scope();

    $rootScope.$apply();
  });

  afterEach(angular.mock.inject(() => {
    I18n.t.restore();
    container.remove();
  }));

  describe('element', () => {
    it('has the queries as options grouped by their public attribute', () => {
      expect(container.find('.ui-autocomplete--category:first').text()).to.eq('Public Queries');
      expect(container.find('.ui-autocomplete--category:first + .ui-menu-item').text()).to.eq('firstQuery');

      expect(container.find('.ui-autocomplete--category:last').text()).to.eq('Private Queries');
      expect(container.find('.ui-autocomplete--category:last + .ui-menu-item').text()).to.eq('secondQuery');
    });
  });
});
