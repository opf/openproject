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

angular
  .module('openproject')
  .config(($stateProvider, $urlRouterProvider, $urlMatcherFactoryProvider) => {

    $urlRouterProvider.when('/work_packages/', '/work_packages');
    $urlMatcherFactoryProvider.strictMode(false);

    var panels = {
      get overview() {
        return {
          url: '/overview',
          reloadOnSearch: false,
          template: '<overview-panel work-package="workPackage"></overview-panel>'
        };
      },

      get watchers() {
        return {
          url: '/watchers',
          reloadOnSearch: false,
          template: '<watchers-panel work-package="workPackage"></watchers-panel>'
        }
      },

      get activity() {
        return {
          url: '/activity',
          reloadOnSearch: false,
          template: '<activity-panel work-package="workPackage"></activity-panel>'
        }
      },

      get activityDetails() {
        var activity = this.activity;
        activity.url = '#{activity_no:\d+}';

        return activity;
      },

      get relations() {
        return {
          url: '/relations',
          reloadOnSearch: false,
          templateUrl: '/templates/work_packages/tabs/relations.html'
        };
      }
    };

    $stateProvider
      .state('work-packages', {
        url: '',
        abstract: true,
        templateUrl: '/components/routing/main/work-packages.html',
        controller: 'WorkPackagesController'
      })

      .state('work-packages.new', {
        url: '/{projects}/{projectPath}/work_packages/new?type&parent_id',
        templateUrl: '/components/routing/main/work-packages.new.html',
        reloadOnSearch: false
      })

      .state('work-packages.copy', {
        url: '/work_packages/{copiedFromWorkPackageId:[0-9]+}/copy',
        templateUrl: '/components/routing/main/work-packages.new.html',
        onEnter: () => {
          document.title = 'Copy Work Package - OpenProject'
        }
      })

      .state('work-packages.edit', {
        url: '/{projects}/{projectPath}/work_packages/{workPackageId}/edit',
        params: {
          projectPath: {value: null, squash: true},
          projects: {value: null, squash: true}
        },

        onEnter: ($state, $stateParams, inplaceEditAll) => {
          inplaceEditAll.start();
          $state.go('work-packages.list.details.overview', $stateParams);
        }
      })

      .state('work-packages.show', {
        url: '/work_packages/{workPackageId:[0-9]+}?query_id&query_props',
        templateUrl: '/components/routing/wp-show/wp.show.html',
        controller: 'WorkPackageShowController',
        controllerAs: 'vm',
        resolve: {
          workPackage: (WorkPackageService, $stateParams) => {
            return WorkPackageService.getWorkPackage($stateParams.workPackageId);
          }
        },
        // HACK
        // This is to avoid problems with the css depending on which page the
        // browser starts from (deep-link). As we have CSS rules that change the
        // layout drastically when on the show action (e.g. position: relative)
        // and this should not be applied to the other states, we need to remove
        // the trigger used in the CSS. The correct fix would be to alter the
        // CSS.
        onEnter: ($state, $timeout) => {
          angular.element('body').addClass('action-show');

          $timeout(() => {
            if ($state.is('work-packages.show')) {
              $state.go('work-packages.show.activity');
            }
          });
        },

        onExit: () => {
          angular.element('body').removeClass('action-show');
        }
      })
      .state('work-packages.show.activity', panels.activity)
      .state('work-packages.show.activity.details', panels.activityDetails)
      .state('work-packages.show.relations', panels.relations)
      .state('work-packages.show.watchers', panels.watchers)

      .state('work-packages.list', {
        url: '/{projects}/{projectPath}/work_packages?query_id&query_props',
        controller: 'WorkPackagesListController',
        templateUrl: '/components/routing/wp-list/wp.list.html',
        params: {
          // value: null makes the parameter optional
          // squash: true avoids duplicate slashes when the paramter is not provided
          projectPath: {value: null, squash: true},
          projects: {value: null, squash: true}
        },
        reloadOnSearch: false,
        // HACK
        // This is to avoid problems with the css depending on which page the
        // browser starts from (deep-link). As we have CSS rules that change the
        // layout drastically when on the index action (e.g. position: absolute,
        // heigt of footer, ...), and this should not be applied to the other
        // states, we need to remove the trigger used in the CSS The correct fix
        // would be to alter the CSS.
        onEnter: () => {
          angular.element('body').addClass('action-index');
        },
        onExit: () => {
          angular.element('body').removeClass('action-index');
        }
      })
      .state('work-packages.list.new', {
        url: '/create_new?type&parent_id',
        templateUrl: '/components/routing/wp-list/wp.list.new.html',
        reloadOnSearch: false
      })
      .state('work-packages.list.copy', {
        url: '/details/{copiedFromWorkPackageId:[0-9]+}/copy',
        templateUrl: '/components/routing/wp-list/wp.list.new.html',
        reloadOnSearch: false
      })
      .state('work-packages.list.details', {
        url: '/details/{workPackageId:[0-9]+}',
        templateUrl: '/components/routing/wp-details/wp.list.details.html',
        controller: 'WorkPackageDetailsController',
        reloadOnSearch: false,
        resolve: {
          workPackage: (WorkPackageService, $stateParams) => {
            return WorkPackageService.getWorkPackage($stateParams.workPackageId);
          }
        }
      })
      .state('work-packages.list.details.overview', panels.overview)
      .state('work-packages.list.details.activity', panels.activity)
      .state('work-packages.list.details.activity.details', panels.activityDetails)
      .state('work-packages.list.details.relations', panels.relations)
      .state('work-packages.list.details.watchers', panels.watchers);
  })

  .run(($location, $rootElement, $browser, $rootScope, $state, $window) => {
    // Our application is still a hybrid one, meaning most routes are still
    // handled by Rails. As such, we disable the default link-hijacking that
    // Angular's HTML5-mode turns on.
    $rootElement.off('click');
    $rootElement.on('click', 'a[data-ui-route]', (event) => {
      if (!jQuery('body').has('div[ui-view]').length || event.ctrlKey || event.metaKey
          || event.which === 2) {

        return;
      }

      // NOTE: making use of event delegation, thus jQuery-only.
      var elm = jQuery(event.target);
      var absHref = elm.prop('href');
      var rewrittenUrl = $location.$$rewrite(absHref);

      if (absHref && !elm.attr('target') && rewrittenUrl && !event.isDefaultPrevented()) {
        event.preventDefault();

        if (rewrittenUrl !== $browser.url()) {
          // update location manually
          $location.$$parse(rewrittenUrl);
          $rootScope.$apply();

          // hack to work around FF6 bug 684208 when scenario runner clicks on links
          $window.angular['ff-684208-preventDefault'] = true;
        }
      }
    });

    $rootScope.$on('$stateChangeStart', (event, toState, toParams) => {
      if (!toParams.projects && toParams.projectPath) {
        toParams.projects = 'projects';
        $state.go(toState, toParams);
      }
    });
    }
  );
