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

// global
angular.module('openproject.config', []);
angular.module('openproject.services', [
  'openproject.uiComponents',
  'openproject.helpers',
  'openproject.workPackages.config',
  'openproject.workPackages.helpers'
]);
angular.module('openproject.helpers', ['openproject.services']);
angular.module('openproject.models', [
  'openproject.workPackages.config',
  'openproject.services'
]);

// timelines
angular.module('openproject.timelines', [
  'openproject.timelines.controllers',
  'openproject.timelines.directives',
  'openproject.uiComponents'
]);
angular.module('openproject.timelines.models', ['openproject.helpers']);
angular.module('openproject.timelines.helpers', []);
angular.module('openproject.timelines.controllers', [
  'openproject.timelines.models'
]);
angular.module('openproject.timelines.services', [
  'openproject.timelines.models',
  'openproject.timelines.helpers'
]);
angular.module('openproject.timelines.directives', [
  'openproject.timelines.models',
  'openproject.timelines.services',
  'openproject.uiComponents',
  'openproject.helpers'
]);

// work packages
angular.module('openproject.workPackages', [
  'openproject.workPackages.controllers',
  'openproject.workPackages.filters',
  'openproject.workPackages.directives',
  'openproject.workPackages.tabs',
  'openproject.uiComponents',
  'ng-context-menu'
]);
angular.module('openproject.workPackages.services', []);
angular.module('openproject.workPackages.helpers', [
  'openproject.helpers',
  'openproject.workPackages.services'
]);
angular.module('openproject.workPackages.filters', [
  'openproject.workPackages.helpers'
]);
angular.module('openproject.workPackages.config', []);
angular.module('openproject.workPackages.controllers', [
  'openproject.models',
  'openproject.workPackages.helpers',
  'openproject.services',
  'openproject.workPackages.config',
  'openproject.layout',
  'btford.modal'
]);
angular.module('openproject.workPackages.directives', [
  'openproject.uiComponents',
  'openproject.services',
  'openproject.workPackages.services'
]);
angular.module('openproject.workPackages.tabs', []);

// messages
angular.module('openproject.messages', ['openproject.messages.controllers']);
angular.module('openproject.messages.controllers', []);

// time entries
angular.module('openproject.timeEntries', [
  'openproject.timeEntries.controllers'
]);
angular.module('openproject.timeEntries.controllers', []);

angular.module('openproject.layout', []);

angular.module('openproject.api', []);

// main app
var openprojectApp = angular.module('openproject', [
  'ui.select2',
  'ui.select2.sortable',
  'ui.date',
  'ui.router',
  'openproject.config',
  'openproject.uiComponents',
  'openproject.timelines',
  'openproject.workPackages',
  'openproject.messages',
  'openproject.timeEntries',
  'ngAnimate',
  'ngSanitize',
  'truncate',
  'feature-flags',
  'openproject.layout',
  'cgBusy',
  'openproject.api',
  'pasvaz.bindonce'
]);

window.appBasePath = jQuery('meta[name=app_base_path]').attr('content') || '';

openprojectApp
  .config([
    '$locationProvider',
    '$httpProvider',
    function($locationProvider, $httpProvider) {
    $locationProvider.html5Mode(true);
    $httpProvider.defaults.headers.common['X-CSRF-TOKEN'] = jQuery('meta[name=csrf-token]').attr('content'); // TODO find a more elegant way to keep the session alive

    // prepend a given base path to requests performed via $http
    $httpProvider.interceptors.push(function ($q) {
      return {
        'request': function (config) {
          config.url = window.appBasePath + config.url;
          return config || $q.when(config);
        }
      };
    });
  }])
  .run([
    '$http',
    'flags',
    function($http, flags) {
    $http.defaults.headers.common.Accept = 'application/json';

    flags.set($http.get('/javascripts/feature-flags.json'));
  }])
  .value('cgBusyDefaults', {
    templateUrl: '/assets/angular-busy/angular-busy.html'
  });
