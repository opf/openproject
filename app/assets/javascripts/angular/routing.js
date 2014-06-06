//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

openprojectApp.config([
  '$stateProvider',
  '$urlRouterProvider',
  function($stateProvider, $urlRouterProvider) {

  // All unmatched routes should be handled by Rails
  // (i.e. invoke a full-page load)
  //
  // a better behaviour here would be for Angular's HTML5-mode to provide an
  // option to turn link hijacking off by default (and use a `target` attribute
  // to turn it on for selected links).

  $urlRouterProvider.otherwise(function($injector, $location) {
    $window = $injector.get('$window');
    $window.location.replace($location.path());
  });

  $stateProvider
    .state('work-packages', {
      url: "/projects/:projectIdentifier/work_packages?query_id",
      abstract: true,
      templateUrl: "/templates/work_packages.html",
      controller: 'WorkPackagesListController',
      resolve: {
        project: function($stateParams, ProjectService) {
          return ProjectService.getProject($stateParams.projectIdentifier);
        },
        availableTypes: function(project) {
          return project.embedded.types;
        }
      }
    })
    .state('work-packages.list', {
      url: "",
      templateUrl: "/templates/work_packages.list.html"
    })
    .state('work-packages.list.details', {
      url: "/{workPackageId:[0-9]+}",
      templateUrl: "/templates/work_packages.list.details.html",
      controller: 'WorkPackageDetailsController'
    });
}]);
