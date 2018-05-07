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

import {openprojectModule} from '../../angular-modules';
import {FirstRouteService} from 'app/components/routing/first-route-service';
import {Transition, TransitionService, UrlMatcherFactory, UrlService} from '@uirouter/core';
import {WorkPackageSplitViewComponent} from 'core-components/routing/wp-split-view/wp-split-view.component';
import {WorkPackagesListComponent} from 'core-components/routing/wp-list/wp-list.component';
import {WorkPackageOverviewTabComponent} from 'core-components/wp-single-view-tabs/overview-tab/overview-tab.component';
import {WorkPackagesFullViewComponent} from 'core-components/routing/wp-full-view/wp-full-view.component';
import {WorkPackageActivityTabComponent} from 'core-components/wp-single-view-tabs/activity-panel/activity-tab.component';
import {WorkPackageRelationsTabComponent} from 'core-components/wp-single-view-tabs/relations-tab/relations-tab.component';
import {WorkPackageWatchersTabComponent} from 'core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import {WorkPackageNewFullViewComponent} from 'core-components/wp-new/wp-new-full-view.component';
import {WorkPackageCopyFullViewComponent} from 'core-components/wp-copy/wp-copy-full-view.component';
import {WorkPackageNewSplitViewComponent} from 'core-components/wp-new/wp-new-split-view.component';
import {WorkPackageCopySplitViewComponent} from 'core-components/wp-copy/wp-copy-split-view.component';

const panels = {
  get overview() {
    return {
      url: '/overview',
      reloadOnSearch: false,
      component: WorkPackageOverviewTabComponent
    };
  },

  get relations() {
    return {
      url: '/relations',
      reloadOnSearch: false,
      component: WorkPackageRelationsTabComponent,
    };
  },

  get watchers() {
    return {
      url: '/watchers',
      reloadOnSearch: false,
      component: WorkPackageWatchersTabComponent,
    };
  },

  get activity() {
    return {
      url: '/activity',
      reloadOnSearch: false,
      component: WorkPackageActivityTabComponent,
    };
  },

  get activityDetails(this:any) {
    var activity = this.activity;
    activity.url = '#{activity_no:\d+}';

    return activity;
  },
};

openprojectModule
  .config(($stateProvider:any,
           $urlRouterProvider:any,
           $urlMatcherFactoryProvider:UrlMatcherFactory) => {

    $urlMatcherFactoryProvider.strictMode(false);

    // Prepend the baseurl to the route to avoid using a base tag
    // For more information, see
    // https://github.com/angular/angular.js/issues/5519
    // https://github.com/opf/openproject/pull/5685
    const baseUrl = (window as any).appBasePath;
    $stateProvider
      .state('work-packages', {
        url: baseUrl + '/{projects}/{projectPath}/work_packages?query_id&query_props',
        abstract: true,
        params: {
          // value: null makes the parameter optional
          // squash: true avoids duplicate slashes when the paramter is not provided
          projectPath: {value: null, squash: true},
          projects: {value: null, squash: true},
          query_id: { dynamic: true },
          query_props: { dynamic: true }
        },
        templateUrl: '/components/routing/main/work-packages.html',
        controller: 'WorkPackagesController'
      })

      .state('work-packages.new', {
        url: '/new?type&parent_id',
        component: WorkPackageNewFullViewComponent,
        reloadOnSearch: false,
        data: {
          allowMovingInEditMode: true
        },
        onEnter: () => angular.element('body').addClass('full-create'),
        onExit: () => angular.element('body').removeClass('full-create'),
      })

      .state('work-packages.copy', {
        url: '/{copiedFromWorkPackageId:[0-9]+}/copy',
        component: WorkPackageCopyFullViewComponent,
        reloadOnSearch: false,
        data: {
          allowMovingInEditMode: true
        },
        onEnter: () => angular.element('body').addClass('action-show'),
        onExit: () => angular.element('body').removeClass('action-show')
      })
      .state('work-packages.show', {
        url: '/{workPackageId:[0-9]+}',
        // Redirect to 'activity' by default.
        redirectTo: 'work-packages.show.activity',
        component: WorkPackagesFullViewComponent,
        onEnter: () => angular.element('body').addClass('action-show'),
        onExit: () => angular.element('body').removeClass('action-show')
      })
      .state('work-packages.show.activity', panels.activity)
      .state('work-packages.show.activity.details', panels.activityDetails)
      .state('work-packages.show.relations', panels.relations)
      .state('work-packages.show.watchers', panels.watchers)

      .state('work-packages.list', {
        url: '',
        component: WorkPackagesListComponent,
        reloadOnSearch: false,
        onEnter: () => angular.element('body').addClass('action-index'),
        onExit: () => angular.element('body').removeClass('action-index')
      })
      .state('work-packages.list.new', {
        url: '/create_new?type&parent_id',
        component: WorkPackageNewSplitViewComponent,
        reloadOnSearch: false,
        data: {
          allowMovingInEditMode: true
        },
        onEnter: () => angular.element('body').addClass('action-create'),
        onExit: () => angular.element('body').removeClass('action-create')
      })
      .state('work-packages.list.copy', {
        url: '/details/{copiedFromWorkPackageId:[0-9]+}/copy',
        component: WorkPackageCopySplitViewComponent,
        reloadOnSearch: false,
        data: {
          allowMovingInEditMode: true
        },
        onEnter: () => angular.element('body').addClass('action-details'),
        onExit: () => angular.element('body').removeClass('action-details')
      })
      .state('work-packages.list.details', {
        redirectTo: 'work-packages.list.details.overview',
        url: '/details/{workPackageId:[0-9]+}',
        component: WorkPackageSplitViewComponent,
        reloadOnSearch: false,
        params: {
          focus: {
            dynamic: true,
            value: true
          }
        },
        onEnter: () => angular.element('body').addClass('action-details'),
        onExit: () => angular.element('body').removeClass('action-details')
      })
      .state('work-packages.list.details.overview', panels.overview)
      .state('work-packages.list.details.activity', panels.activity)
      .state('work-packages.list.details.activity.details', panels.activityDetails)
      .state('work-packages.list.details.relations', panels.relations)
      .state('work-packages.list.details.watchers', panels.watchers);
  })

  .run(($location:ng.ILocationService,
        $rootElement:ng.IRootElementService,
        firstRoute:FirstRouteService,
        $timeout:ng.ITimeoutService,
        $rootScope:ng.IRootScopeService,
        $trace:any,
        $transitions:TransitionService,
        $window:ng.IWindowService) => {

      $trace.enable(1);

      // Our application is still a hybrid one, meaning most routes are still
      // handled by Rails. As such, we disable the default link-hijacking that
      // Angular's HTML5-mode turns on.
      $rootElement.off('click');

      // Prevent angular handling clicks on href="#" links from other libraries
      // (especially jquery-ui and its datepicker) from routing to <base url>/#
      angular.element('body').on('click', 'a[href="#"]', function (evt) {
        evt.preventDefault();
      });

      $transitions.onStart({}, function (transition:Transition) {
        const $state = transition.router.stateService;
        const toParams = transition.params('to');
        const toState = transition.to();

        // We need to distinguish between actions that should run on the initial page load
        // (ie. openining a new tab in the details view should focus on the element in the table)
        // so we need to know which route we visited initially
        firstRoute.setIfFirst(toState.name, toParams);


        if (transition.options().notify !== false) {
          $rootScope.$emit('notifications.clearAll');
        }

        const projectIdentifier = toParams.projectPath || ($rootScope as any)['projectIdentifier'];

        if (!toParams.projects && projectIdentifier) {
          const newParams = _.clone(toParams);
          _.assign(newParams, {projectPath: projectIdentifier, projects: 'projects'});
          return $state.target(toState, newParams, {location: 'replace'});
        }

        return true;
      });
    });
