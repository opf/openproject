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

import {FirstRouteService} from 'app/components/routing/first-route-service';
import {StateDeclaration, StateRegistry, Transition, TransitionService, UrlService} from '@uirouter/core';
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
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {Injector} from "@angular/core";
import {WorkPackagesBaseComponent} from "core-components/routing/main/work-packages-base.component";

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

// Prepend the baseurl to the route to avoid using a base tag
// For more information, see
// https://github.com/angular/angular.js/issues/5519
// https://github.com/opf/openproject/pull/5685
const baseUrl = ''; // (window as any).appBasePath;
export const OPENPROJECT_ROUTES:StateDeclaration[] = [
  {
    name: 'work-packages',
    component: WorkPackagesBaseComponent,
    url: baseUrl + '/{projects}/{projectPath}/work_packages?query_id&query_props',
    abstract: true,
    params: {
      // value: null makes the parameter optional
      // squash: true avoids duplicate slashes when the paramter is not provided
      projectPath: {value: null, squash: true},
      projects: {value: null, squash: true},
      query_id: {dynamic: true},
      query_props: {dynamic: true}
    }
  },
  {
    name: 'work-packages.new',
    url: '/new?type&parent_id',
    component: WorkPackageNewFullViewComponent,
    reloadOnSearch: false,
    data: {
      allowMovingInEditMode: true
    },
    onEnter: () => jQuery('body').addClass('full-create'),
    onExit: () => jQuery('body').removeClass('full-create'),
  },
  {
    name: 'work-packages.copy',
    url: '/{copiedFromWorkPackageId:[0-9]+}/copy',
    component: WorkPackageCopyFullViewComponent,
    reloadOnSearch: false,
    data: {
      allowMovingInEditMode: true
    },
    onEnter: () => jQuery('body').addClass('action-show'),
    onExit: () => jQuery('body').removeClass('action-show')
  },
  {
    name: 'work-packages.show',
    url: '/{workPackageId:[0-9]+}',
    // Redirect to 'activity' by default.
    redirectTo: 'work-packages.show.activity',
    component: WorkPackagesFullViewComponent,
    onEnter: () => jQuery('body').addClass('action-show'),
    onExit: () => jQuery('body').removeClass('action-show')
  },
  _.assign(panels.activity, {name: 'work-packages.show.activity'}),
  _.assign(panels.activityDetails, {name: 'work-packages.show.activity.details'}),
  _.assign(panels.relations, {name: 'work-packages.show.relations'}),
  _.assign(panels.watchers, {name: 'work-packages.show.watchers'}),
  {
    name: 'work-packages.list',
    url: '',
    component: WorkPackagesListComponent,
    reloadOnSearch: false,
    onEnter: () => jQuery('body').addClass('action-index'),
    onExit: () => jQuery('body').removeClass('action-index')
  },
  {
    name: 'work-packages.list.new',
    url: '/create_new?type&parent_id',
    component: WorkPackageNewSplitViewComponent,
    reloadOnSearch: false,
    data: {
      allowMovingInEditMode: true
    },
    onEnter: () => jQuery('body').addClass('action-create'),
    onExit: () => jQuery('body').removeClass('action-create')
  },
  {
    name: 'work-packages.list.copy',
    url: '/details/{copiedFromWorkPackageId:[0-9]+}/copy',
    component: WorkPackageCopySplitViewComponent,
    reloadOnSearch: false,
    data: {
      allowMovingInEditMode: true
    },
    onEnter: () => jQuery('body').addClass('action-details'),
    onExit: () => jQuery('body').removeClass('action-details')
  },
  {
    name: 'work-packages.list.details',
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
    onEnter: () => jQuery('body').addClass('action-details'),
    onExit: () => jQuery('body').removeClass('action-details')
  },
  _.extend(panels.overview, {name: 'work-packages.list.details.overview'}),
  _.extend(panels.activity, {name: 'work-packages.list.details.activity'}),
  _.extend(panels.activityDetails, {name: 'work-packages.list.details.activity.details'}),
  _.extend(panels.relations, {name: 'work-packages.list.details.relations'}),
  _.extend(panels.watchers, {name: 'work-packages.list.details.watchers'})
];

export function initializeUiRouterConfiguration(injector:Injector) {
  return () => {
    const $transitions:TransitionService = injector.get(TransitionService);
    const notificationsService:NotificationsService = injector.get(NotificationsService);
    const currentProject:CurrentProjectService = injector.get(CurrentProjectService);
    const firstRoute:FirstRouteService = injector.get(FirstRouteService);
    const stateRegistry:StateRegistry = injector.get(StateRegistry);
    const urlService:UrlService = injector.get(UrlService);

    // Register routes in this initializer instead forRoot({states: ...}) due to AOT
    _.each(OPENPROJECT_ROUTES, route => {
      stateRegistry.register(route);
    });

    // Synchronize now that routes are updated
    urlService.sync();

    // Our application is still a hybrid one, meaning most routes are still
    // handled by Rails. As such, we disable the default link-hijacking that
    // Angular's HTML5-mode turns on.
    jQuery(document.body)
      .off('click')
      // Prevent angular handling clicks on href="#..." links from other libraries
      // (especially jquery-ui and its datepicker) from routing to <base url>/#
      .on('click', 'a[href^="#"]', (evt) => {
        evt.preventDefault();

        // Set the location to the hash if there is any
        // Since with the base tag, links like href="#whatever" otherwise target to <base>/#whatever
        const link = evt.target.getAttribute('href');
        if (link && link !== '#') {
          window.location.hash = link;
        }

        return false;
      });

    $transitions.onStart({}, function(transition:Transition) {
      const $state = transition.router.stateService;
      const toParams = transition.params('to');
      const toState = transition.to();

      // We need to distinguish between actions that should run on the initial page load
      // (ie. openining a new tab in the details view should focus on the element in the table)
      // so we need to know which route we visited initially
      firstRoute.setIfFirst(toState.name, toParams);


      // Clear all notifications when actually moving between states.
      if (transition.to().name !== transition.from().name) {
        notificationsService.clear();
      }

      const projectIdentifier = toParams.projectPath || currentProject.identifier;

      if (!toParams.projects && projectIdentifier) {
        const newParams = _.clone(toParams);
        _.assign(newParams, {projectPath: projectIdentifier, projects: 'projects'});
        return $state.target(toState, newParams, {location: 'replace'});
      }

      return true;
    });
  };
}
