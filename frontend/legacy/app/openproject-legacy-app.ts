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


import {ExpressionService} from "../../common/expression.service";
require('angular');

var angularDragula:any = require('angular-dragula');
export const opTemplatesModule = angular.module('openproject.templates', []);
export const openprojectLegacyModule = angular.module('OpenProjectLegacy', [
  angularDragula(angular)
]);

// Bootstrap app

openprojectLegacyModule
  .config([
    '$compileProvider',
    '$httpProvider',
    function($compileProvider:any, $httpProvider:any) {

      // Disable debugInfo outside development mode
      $compileProvider.debugInfoEnabled(window.OpenProject.environment === 'development');

      $httpProvider.defaults.headers.common['X-CSRF-TOKEN'] = jQuery(
        'meta[name=csrf-token]').attr('content');
      $httpProvider.defaults.headers.common['X-Authentication-Scheme'] = 'Session';
      // Add X-Requested-With for request.xhr?
      $httpProvider.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
      // prepend a given base path to requests performed via $http
      //
      $httpProvider.interceptors.push(function($q:ng.IQService) {
        return {
          'request': function(config:any) {
            // OpenProject can run in a subpath e.g. https://mydomain/open_project.
            // We append the path found as the base-tag value to all http requests
            // to the server except:
            //   * when the path is already appended
            //   * when we are getting a template
            if (!config.url.match('(^/templates|\\.html$|^' + window.appBasePath + ')')) {
              config.url = window.appBasePath + (config.url as string);
            }

            return config || $q.when(config);
          }
        };
      });
    }
  ])
  .run([
    '$rootScope',
    function($rootScope:any) {
      // Set the escaping target of opening double curly braces
      // This is what returned by rails-angular-xss when it discoveres double open curly braces
      // See https://github.com/opf/rails-angular-xss for more information.
      $rootScope.DOUBLE_LEFT_CURLY_BRACE = ExpressionService.UNESCAPED_EXPRESSION;

      // Mark the bootstrap has run for testing purposes.
      document.body.classList.add('__ng-bootstrap-has-run');

      $rootScope.$on('$stateChangeError',
        function(event:JQueryEventObject){
          event.preventDefault();
          // transitionTo() promise will be rejected with
          // a 'transition prevented' error
        });
    }
  ]);

var requireComponent = require.context('./components/', true, /^((?!\.(test|spec)).)*\.(js|ts|html)$/);
requireComponent.keys().forEach(requireComponent);

var requireServices = require.context('./services/', true, /^((?!\.(test|spec)).)*\.(js|ts|html)$/);
requireServices.keys().forEach(requireServices);

// Load all dynamically linked plugins
var requirePlugins = require.context('./plugins/', true, /^((?!\.(test|spec)).)*\.(js|ts|html)$/);
requirePlugins.keys().forEach(requirePlugins);
