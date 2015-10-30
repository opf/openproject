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

var I18n = require('./vendor/i18n');

// standard locales
I18n.translations.en = require("locales/js-en.yml").en;

I18n.addTranslations = function(locale, translations) {
  if (I18n.translations[locale] === undefined) {
    I18n.translations[locale] = translations;
  }
  else {
    I18n.translations[locale] = _.merge(I18n.translations[locale], translations);
  }
};

require('angular-animate');
require('angular-aria');
require('angular-modal');

// depends on the html element having a 'lang' attribute
var documentLang = angular.element('html').attr('lang') || 'en';
require('angular-i18n/angular-locale_' + documentLang + '.js');

require('angular-ui-router');

require('angular-ui-date');
require('angular-truncate');
require('angular-feature-flags');

require('angular-busy/dist/angular-busy');
require('angular-busy/dist/angular-busy.css');

require('angular-context-menu');
require('angular-elastic');
require('angular-cache');
require('mousetrap');
require('ngFileUpload');

// global
angular.module('openproject.uiComponents', ['ui.select', 'ngSanitize'])
.run(['$rootScope', function($rootScope){
  $rootScope.I18n = I18n;
}]);
angular.module('openproject.config', []);
angular.module(
  'openproject.services', [
    'openproject.uiComponents',
    'openproject.helpers',
    'openproject.workPackages.config',
    'openproject.workPackages.helpers',
    'angular-cache'
  ]);
angular.module('openproject.helpers', ['openproject.services']);
angular
  .module('openproject.models', [
    'openproject.workPackages.config',
    'openproject.services'
  ]);
angular.module('openproject.viewModels', ['openproject.services']);

// timelines
angular.module('openproject.timelines', [
  'openproject.timelines.controllers',
  'openproject.timelines.directives',
  'openproject.uiComponents'
]);
angular.module('openproject.timelines.models', ['openproject.helpers']);
angular
  .module('openproject.timelines.helpers', []);
angular.module(
  'openproject.timelines.controllers', [
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
  'openproject.workPackages.activities',
  'openproject.workPackages.controllers',
  'openproject.workPackages.filters',
  'openproject.workPackages.directives',
  'openproject.workPackages.tabs',
  'openproject.uiComponents',
  'ng-context-menu',
  'ngFileUpload'
]);
angular.module('openproject.workPackages.services', []);
angular.module(
  'openproject.workPackages.helpers', [
    'openproject.helpers',
    'openproject.workPackages.services'
  ]);
angular.module('openproject.workPackages.filters', [
  'openproject.workPackages.helpers'
]);
angular.module('openproject.workPackages.config', []);
angular.module(
  'openproject.workPackages.controllers', [
    'openproject.models',
    'openproject.viewModels',
    'openproject.workPackages.helpers',
    'openproject.services',
    'openproject.workPackages.config',
    'openproject.layout',
    'btford.modal'
  ]);
angular.module('openproject.workPackages.models', []);
angular.module(
  'openproject.workPackages.directives', [
    'openproject.uiComponents',
    'openproject.services',
    'openproject.workPackages.services',
    'openproject.workPackages.models'
  ]);
angular.module('openproject.workPackages.tabs', []);
angular.module('openproject.workPackages.activities', []);

// messages
angular.module('openproject.messages', [
  'openproject.messages.controllers'
]);
angular.module('openproject.messages.controllers', []);

// time entries
angular.module('openproject.timeEntries', [
  'openproject.timeEntries.controllers'
]);
angular.module('openproject.timeEntries.controllers', []);

angular.module('openproject.layout', [
  'openproject.layout.controllers',
  'ui.router'
]);
angular.module('openproject.layout.controllers', []);

angular.module('openproject.api', []);

angular.module('openproject.templates', []);

// main app
var openprojectApp = angular.module('openproject', [
  'ui.date',
  'ui.router',
  'openproject.config',
  'openproject.uiComponents',
  'openproject.timelines',
  'openproject.workPackages',
  'openproject.messages',
  'openproject.timeEntries',
  'ngAnimate',
  'ngAria',
  'ngSanitize',
  'truncate',
  'feature-flags',
  'openproject.layout',
  'cgBusy',
  'openproject.api',
  'openproject.templates',
  'monospaced.elastic'
]);

window.appBasePath = jQuery('meta[name=app_base_path]').attr('content') ||
  '';

openprojectApp
  .config([
    '$locationProvider',
    '$httpProvider',
    function($locationProvider, $httpProvider) {
      $locationProvider.html5Mode(true);
      $httpProvider.defaults.headers.common['X-CSRF-TOKEN'] = jQuery(
        'meta[name=csrf-token]').attr('content'); // TODO find a more elegant way to keep the session alive
      $httpProvider.defaults.headers.common['X-Authentication-Scheme'] = 'Session';
      // prepend a given base path to requests performed via $http
      //
      // NOTE: this does not apply to Hyperagent-based queries, which instead use
      //       jQuery's AJAX implementation.
      $httpProvider.interceptors.push(function($q) {
        return {
          'request': function(config) {
            // OpenProject can run in a subpath e.g. https://mydomain/open_project.
            // We append the path found as the base-tag value to all http requests
            // to the server except:
            //   * when the path is already appended
            //   * when we are getting a template
            if (!config.url.match('(^/templates|\\.html$|^' + window.appBasePath + ')')) {
              config.url = window.appBasePath + config.url;
            }

            return config || $q.when(config);
          }
        };
      });
    }
  ])
  .run([
    '$http',
    '$rootScope',
    '$window',
    'featureFlags',
    'TimezoneService',
    'CacheService',
    'KeyboardShortcutService',
    function($http,
             $rootScope,
             $window,
             flags,
             TimezoneService,
             CacheService,
             KeyboardShortcutService) {
      $http.defaults.headers.common.Accept = 'application/json';

      $rootScope.showNavigation =
        $window.sessionStorage.getItem('openproject:navigation-toggle') !==
        'collapsed';

      flags.set($http.get('/javascripts/feature-flags.json'));
      TimezoneService.setupLocale();
      KeyboardShortcutService.activate();

      // Disable the CacheService for test environment
      if ($window.openProject.environment === 'test') {
        CacheService.disableCaching();
      }

      // at the moment of adding this code it was mostly used to
      // keep the previous state for the code to know where
      // to redirect the user on cancel new work package form
      $rootScope.$on('$stateChangeSuccess', function(ev, to, toParams, from, fromParams) {
          $rootScope.previousState = {
            name: from.name,
            params: fromParams
          };
      });
    }
  ]);

require('./api');

angular.module('openproject.config')
  .service('ConfigurationService', [
    'PathHelper',
    '$q',
    '$http',
    require('./config/configuration-service')
  ]);

require('./helpers');
require('./layout');
require('./messages');
require('./models');
require('./routing');
require('./services');
require('./time_entries');
require('./timelines');
require('./ui_components');
require('./work_packages');

var requireTemplate = require.context('./templates', true, /\.html$/);

requireTemplate.keys().forEach(requireTemplate);
require('!ngtemplate?module=openproject.templates!html!angular-busy/angular-busy.html');

require('./typescript_demo/demo.controller');
