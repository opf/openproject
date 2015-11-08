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

angular.module('openproject')

.config([
  '$stateProvider',
  '$urlRouterProvider',
  function($stateProvider, $urlRouterProvider) {
  // redirect to default activity tab when user lands at /work_packages/:id
  // TODO: Preserve #note-4 part of the URL.
  $urlRouterProvider.when('/work_packages/{id}', function ($match) {
    if($match.id.length === 0) {
      return '/work_packages';
    }
    else {
      return '/work_packages/' + $match.id + '/activity';
    }
  });

  $stateProvider
    .state('work-packages', {
      url: '',
      abstract: true,
      templateUrl: '/templates/work_packages.html',
      controller: 'WorkPackagesController',
      resolve: {
        latestTab: function($state) {
          var stateName = 'work-packages.list.details.overview'; // the default tab

          return {
            getStateName: function() {
              return stateName;
            },
            registerState: function() {
              stateName = $state.current.name;
            }
          };
        }
      }
    })

    .state('work-packages.show', {
      url: '/work_packages/{workPackageId:[0-9]+}?query_props',
      templateUrl: '/templates/work_packages.show.html',
      controller: 'WorkPackageShowController',
      controllerAs: 'vm',
      abstract: true,
      resolve: {
        workPackage: function(WorkPackageService, $stateParams) {
          var wsPromise = WorkPackageService.getWorkPackage($stateParams.workPackageId);

          wsPromise.catch(function(){
            location.href = '/projects';
          });

          return wsPromise;
        },
        // TODO hack, get rid of latestTab in ShowController
        latestTab: function($state) {
          var stateName = 'work-package.overview'; // the default tab

          return {
            getStateName: function() {
              return stateName;
            },
            registerState: function() {
              stateName = $state.current.name;
            }
          };
        }
      },
      // HACK
      // This is to avoid problems with the css depending on which page the
      // browser starts from (deep-link). As we have CSS rules that change the
      // layout drastically when on the show action (e.g. position: relative)
      // and this should not be applied to the other states, we need to remove
      // the trigger used in the CSS. The correct fix would be to alter the
      // CSS.
      onEnter: function(){
        angular.element('body').addClass('action-show');
      },
      onExit: function(){
        angular.element('body').removeClass('action-show');
      }
    })
    .state('work-packages.show.activity', {
      url: '/activity',
      templateUrl: '/templates/work_packages/tabs/activity.html'
    })
    .state('work-packages.show.activity.details', {
      url: '#{activity_no:[0-9]+}',
      templateUrl: '/templates/work_packages/tabs/activity.html'
    })
    .state('work-packages.show.relations', {
      url: '/relations',
      templateUrl: '/templates/work_packages/tabs/relations.html'
    })
    .state('work-packages.show.watchers', {
      url: '/watchers',
      controller: 'DetailsTabWatchersController',
      templateUrl: '/templates/work_packages/tabs/watchers.html',
      controllerAs: 'watchers'
    })

    .state('work-packages.list', {
      url: '/{projects}/{projectPath}/work_packages?query_id&query_props',
      controller: 'WorkPackagesListController',
      templateUrl: '/templates/work_packages.list.html',
      params: {
        // value: null makes the parameter optional
        // squash: true avoids duplicate slashes when the paramter is not provided
        projectPath: { value: null, squash: true },
        projects: { value: null, squash: true }
      },
      reloadOnSearch: false,
      // HACK
      // This is to avoid problems with the css depending on which page the
      // browser starts from (deep-link). As we have CSS rules that change the
      // layout drastically when on the index action (e.g. position: absolute,
      // heigt of footer, ...), and this should not be applied to the other
      // states, we need to remove the trigger used in the CSS The correct fix
      // would be to alter the CSS.
      onEnter: function(){
        angular.element('body').addClass('action-index');
      },
      onExit: function(){
        angular.element('body').removeClass('action-index');
      }
    })
    .state('work-packages.list.new', {
      url: '/create_new?type',
      controller: 'WorkPackageNewController',
      controllerAs: 'vm',
      templateUrl: '/components/routes/templates/work-package-new.route.html',
      reloadOnSearch: false
    })
    .state('work-packages.list.details', {
      url: '/details/{workPackageId:[0-9]+}',
      templateUrl: '/templates/work_packages.list.details.html',
      controller: 'WorkPackageDetailsController',
      reloadOnSearch: false,
      resolve: {
        workPackage: function(WorkPackageService, $stateParams) {
          return WorkPackageService.getWorkPackage($stateParams.workPackageId);
        }
      }
    })
    .state('work-packages.list.details.overview', {
      url: '/overview',
      controller: 'DetailsTabOverviewController',
      templateUrl: '/templates/work_packages/tabs/overview.html',
      controllerAs: 'vm',
    })
    .state('work-packages.list.details.activity', {
      url: '/activity',
      templateUrl: '/templates/work_packages/tabs/activity.html',
    })
    .state('work-packages.list.details.activity.details', {
      url: '#{activity_no:[0-9]+}',
      templateUrl: '/templates/work_packages/tabs/activity.html'
    })
    .state('work-packages.list.details.relations', {
      url: '/relations',
      templateUrl: '/templates/work_packages/tabs/relations.html',
    })
    .state('work-packages.list.details.watchers', {
      url: '/watchers',
      controller: 'DetailsTabWatchersController',
      templateUrl: '/templates/work_packages/tabs/watchers.html',
      controllerAs: 'watchers',
    });
}])

.run([
  '$location',
  '$rootElement',
  '$browser',
  '$rootScope',
  '$state',
  function($location, $rootElement, $browser, $rootScope, $state) {
    // Our application is still a hybrid one, meaning most routes are still
    // handled by Rails. As such, we disable the default link-hijacking that
    // Angular's HTML5-mode turns on.
    $rootElement.off('click');
    $rootElement.on('click', 'a[data-ui-route]', function(event) {
      if (!jQuery('body').has('div[ui-view]').length) { return; }
      if (event.ctrlKey || event.metaKey || event.which === 2) { return; }

      // NOTE: making use of event delegation, thus jQuery-only.
      var elm          = jQuery(event.target);
      var absHref      = elm.prop('href');
      var rewrittenUrl = $location.$$rewrite(absHref);

      if (absHref && !elm.attr('target') &&
        rewrittenUrl &&
        !event.isDefaultPrevented()) {

        event.preventDefault();
        if (rewrittenUrl !== $browser.url()) {
          // update location manually
          $location.$$parse(rewrittenUrl);
          $rootScope.$apply();
          // hack to work around FF6 bug 684208 when scenario runner clicks on links
          window.angular['ff-684208-preventDefault'] = true;
        }
      }
    });

    $rootScope.$on('$stateChangeStart', function(event, toState, toParams){
      var matchListState = toState.name.match(/work-packages\.list.*/);

      if (matchListState && !toParams.projects && toParams.projectPath) {
        toParams.projects = 'projects';
        $state.go(toState, toParams);
      }
    });
  }
]);
