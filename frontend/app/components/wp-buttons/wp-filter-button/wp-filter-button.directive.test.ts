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

import {WorkPackageFilterButtonController} from './wp-filter-button.directive';

var expect = chai.expect;

describe('wpFilterButton directive', () => {
  var scope:ng.IScope;
  var element:ng.IAugmentedJQuery;
  var controller:WorkPackageFilterButtonController;
  var state:any;
  var subscribe:Function;
  var compile:any;

  beforeEach(angular.mock.module(
    'openproject.wpButtons',
    'openproject.templates'
  ));

  let doCompile = () => {
    compile(element)(scope);
    scope.$apply();

    controller = element.controller('wpFilterButton');
  }

  beforeEach(angular.mock.module('openproject.services', function($provide:any) {
    var wpTableFilters = {
      observeOnScope: function(scope:ng.IScope) {
        return {
          subscribe: subscribe
        }
      }
    };

    $provide.constant('wpTableFilters', wpTableFilters);
  }));


  beforeEach(angular.mock.inject(($compile:any, $rootScope:ng.IScope) => {
    var html = '<wp-filter-button></wp-filter-button>';
    element = angular.element(html);
    scope = $rootScope.$new();
    compile = $compile;

    state = {
      current: ['mock', 'mock', 'mock']
    }

    subscribe = function(callback:Function) {
      callback(state);
    }
  }));

  describe('when getting the filterCount', () => {
    it('returns the length of the current array', () => {
      doCompile();

      expect(controller.filterCount).to.eq(state.current.length);
    });
  });

  describe('initialized', () => {
    it('is true', () => {
      doCompile();

      expect(controller.initialized).to.eq(true);
    });

    describe('when not having received a message yet', () => {
      it('is false', () => {
        subscribe = function(callback:Function) {
          //do nothing
        }

        doCompile();

        expect(controller.initialized).to.eq(false);
      });
    });
  });

  describe('badge element', () => {
    it ('is the length of the current array', () => {
      doCompile();

      expect(element.find('.badge').text()).to.eq(state.current.length.toString());
    });
  });
});
