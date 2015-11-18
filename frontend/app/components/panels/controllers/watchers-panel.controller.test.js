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

describe('WatchersPanelController', function() {
  'use strict';

  beforeEach(angular.mock.module('openproject.workPackages.controllers'));

  var $controller, $rootScope;
  beforeEach(inject(['$controller', '$rootScope', function(ctrl, root) {
    $controller = ctrl;
    $rootScope = root;
  }]));

  var workPackage = {
    links: {
      watchers: {
        url: function() {
          return '/work_packages/123/watchers';
        }
      },
      availableWatchers: {
        url: function() {
          return '/work_packages/123/available_watchers';
        }
      }
    }
  };


  it('should exist', function() {
    var locals = {
          $scope: $rootScope.$new()
        };

    locals.$scope.workPackage = workPackage;
    expect($controller('WatchersPanelController', locals)).to.exist;
  });

  it('should not work without a work workPackage', function() {
    var locals = {
      $scope: $rootScope.$new()
    };

    expect(function() {
      $controller('WatchersPanelController', locals);
    }).to.throw;
  });
});

