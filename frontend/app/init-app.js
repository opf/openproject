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

require('angular-animate');
require('angular-aria');
require('angular-modal');

// depends on the html element having a 'lang' attribute
var documentLang = (angular.element('html').attr('lang') || 'en').toLowerCase();
require('angular-i18n/angular-locale_' + documentLang + '.js');

require('angular-ui-router');

require('angular-truncate');

require('angular-busy/dist/angular-busy');
require('angular-busy/dist/angular-busy.css');

require('angular-context-menu');
require('angular-elastic');
require('angular-cache');
require('mousetrap');
require('ngFileUpload');

var opApp = require('./angular-modules.ts').default;

window.appBasePath = jQuery('meta[name=app_base_path]').attr('content') || '';

opApp
    .config([
      '$compileProvider',
      '$locationProvider',
      '$httpProvider',
      function($compileProvider, $locationProvider, $httpProvider) {

        // Disable debugInfo outside development mode
        $compileProvider.debugInfoEnabled(window.openProject.environment === 'development');

        $locationProvider.html5Mode(true);
        $httpProvider.defaults.headers.common['X-CSRF-TOKEN'] = jQuery(
            'meta[name=csrf-token]').attr('content');
        $httpProvider.defaults.headers.common['X-Authentication-Scheme'] = 'Session';
        // Add X-Requested-With for request.xhr?
        $httpProvider.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
        // prepend a given base path to requests performed via $http
        //
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

        // add global event handlers
        angular.element('body').attr('global-drag-and-drop-handler','');
      }
    ])
    .run([
      '$http',
      '$rootScope',
      '$window',
      'TimezoneService',
      'ExpressionService',
      'CacheService',
      'KeyboardShortcutService',
      function($http,
               $rootScope,
               $window,
               TimezoneService,
               ExpressionService,
               CacheService,
               KeyboardShortcutService) {
        $http.defaults.headers.common.Accept = 'application/json';

        // Set the escaping target of opening double curly braces
        // This is what returned by rails-angular-xss when it discoveres double open curly braces
        // See https://github.com/opf/rails-angular-xss for more information.
        $rootScope.DOUBLE_LEFT_CURLY_BRACE = ExpressionService.UNESCAPED_EXPRESSION;

        $rootScope.showNavigation =
            $window.sessionStorage.getItem('openproject:navigation-toggle') !==
            'collapsed';

        TimezoneService.setupLocale();
        KeyboardShortcutService.activate();

        // Disable the CacheService for test environment
        if ($window.openProject.environment === 'test') {
          CacheService.disableCaching();
        }

        $rootScope.$on('$stateChangeError',
            function(event){
              event.preventDefault();
              // transitionTo() promise will be rejected with
              // a 'transition prevented' error
            });

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

require('./helpers');
require('./layout');
require('./messages');
require('./models');
require('./services');
require('./time_entries');
require('./timelines');
require('./ui_components');
require('./work_packages');

var requireTemplate = require.context('./templates', true, /\.html$/);
requireTemplate.keys().forEach(requireTemplate);

require('!ngtemplate?module=openproject.templates!html!angular-busy/angular-busy.html');

var requireComponent = require.context('./components/', true, /^((?!\.(test|spec)).)*\.(js|ts|html)$/);
requireComponent.keys().forEach(requireComponent);
