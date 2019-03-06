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

import {StateService, Transition, TransitionService, UIRouter, UrlService} from '@uirouter/core';
import {INotification, NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {Injector} from "@angular/core";
import {FirstRouteService} from "core-app/modules/router/first-route-service";
import {StatesModule} from "@uirouter/angular";
import {appBaseSelector, ApplicationBaseComponent} from "core-app/modules/router/base/application-base.component";
import {BackRoutingService} from "core-app/modules/common/back-routing/back-routing.service";

export const OPENPROJECT_ROUTES = [
  {
    name: 'root',
    url: '/{projects}/{projectPath}',
    component: ApplicationBaseComponent,
    abstract: true,
    params: {
      // value: null makes the parameter optional
      // squash: true avoids duplicate slashes when the parameter is not provided
      projectPath: {type: 'path', value: null, squash: true},
      projects: {type: 'path', value: null, squash: true},

      // Allow passing of flash messages after routes load
      flash_message: { dynamic: true, value: null, inherit: false }
    }
  },
  // We could lazily load work packages module already,
  // but e.g., the plugin context requires service from it.
  // {
  //   name: 'work-packages.**',
  //   parent: 'root',
  //   url: '/work_packages/**',
  //   loadChildren: '../work_packages/openproject-work-packages.module#OpenprojectWorkPackagesModule'
  // },
];

/**
 * Add or remove a body class. Helper for ui-router body classes functionality
 *
 * @param className
 * @param action
 */
export function bodyClass(className:string|null|undefined, action:'add'|'remove' = 'add') {
  if (className) {
    document.body.classList[action](className);
  }
}

export function uiRouterConfiguration(uiRouter:UIRouter, injector:Injector, module:StatesModule) {
  // Allow optional trailing slashes
  uiRouter.urlService.config.strictMode(false);

  // Register custom URL params type
  // to ensure query props are correctly set
  uiRouter.urlService.config.type(
    'opQueryString',
    {
      encode: encodeURIComponent,
      decode: decodeURIComponent,
      raw: true,
      dynamic: true,
      is: (val:unknown) => typeof(val) === 'string',
      equals: (a:any, b:any) => _.isEqual(a, b),
    }
  );
}

export function initializeUiRouterListeners(injector:Injector) {
  return () => {
    const $transitions:TransitionService = injector.get(TransitionService);
    const stateService = injector.get(StateService);
    const notificationsService:NotificationsService = injector.get(NotificationsService);
    const currentProject:CurrentProjectService = injector.get(CurrentProjectService);
    const firstRoute:FirstRouteService = injector.get(FirstRouteService);
    const backRoutingService:BackRoutingService = injector.get(BackRoutingService);

    // Check whether we are running within our complete app, or only within some other bootstrapped
    // component
    let wpBase = document.querySelector(appBaseSelector);

    // Apply classes from bodyClasses in each state definition
    // This was defined as onEnter, onExit functions in each state before
    // but since AOT doesn't allow anonymous functions, we can't re-use them now.
    $transitions.onEnter({}, function(transition:Transition) {
      const toState = transition.to();

      // Add body class when leaving this state
      bodyClass(_.get(toState, 'data.bodyClasses'), 'add');
    });

    $transitions.onExit({}, function(transition:Transition) {
      const fromState = transition.from();

      // Remove body class when leaving this state
      bodyClass(_.get(fromState, 'data.bodyClasses'), 'remove');
    });

    $transitions.onStart({}, function(transition:Transition) {
      const $state = transition.router.stateService;
      const toParams = transition.params('to');
      const fromState = transition.from();
      const toState = transition.to();

      // Remove start_onboarding_tour param if set
      if (toParams.start_onboarding_tour && toState.name !== 'work-packages.list') {
        const paramsCopy = Object.assign({}, transition.params());
        paramsCopy.start_onboarding_tour = undefined;
        return $state.target(transition.to(), paramsCopy);
      }

      // Set backRoute to know where we came from
      if (fromState.name &&
          fromState.data &&
          toState.data &&
          fromState.data.parent !== toState.data.parent) {
        const paramsFromCopy = Object.assign({}, transition.params('from'));
        backRoutingService.setBackRoute({ name: fromState.name, params: paramsFromCopy });
      }

      // Reset profiler, if we're actually profiling
      const profiler:any = (window as any).MiniProfiler;
      profiler && profiler.pageTransition();

      // Remove and add any body class definitions for entering
      // and exiting states.
      bodyClass(_.get(toState, 'data.bodyClasses'), 'add');

      // Abort the transition and move to the url instead
      if (wpBase === null) {

        // Only move to the URL if we're not coming from an initial URL load
        // (cases like /work_packages/invalid/activity which render a 403 without frontend,
        // but trigger the ui-router state)
        if (!(transition.options().source === 'url' || firstRoute.isEmpty)) {
          const target = stateService.href(toState, toParams);
          window.location.href = target;
          return false;
        }
      }

      // We need to distinguish between actions that should run on the initial page load
      // (ie. openining a new tab in the details view should focus on the element in the table)
      // so we need to know which route we visited initially
      firstRoute.setIfFirst(toState.name, toParams);

      // Clear all notifications when actually moving between states.
      if (transition.to().name !== transition.from().name) {
        notificationsService.clear();
      }

      // Add new notifications if passed to params
      if (toParams.flash_message) {
        notificationsService.add(toParams.flash_message as INotification);
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
