// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {StateDeclaration, StateService, Transition, TransitionService, UIRouter} from '@uirouter/core';
import {INotification, NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {Injector} from "@angular/core";
import {FirstRouteService} from "core-app/modules/router/first-route-service";
import {Ng2StateDeclaration, StatesModule} from "@uirouter/angular";
import {appBaseSelector, ApplicationBaseComponent} from "core-app/modules/router/base/application-base.component";
import {BackRoutingService} from "core-app/modules/common/back-routing/back-routing.service";

export const OPENPROJECT_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'root',
    url: '/{projects}/{projectPath}',
    component: ApplicationBaseComponent,
    abstract: true,
    params: {
      // value: null makes the parameter optional
      // squash: true avoids duplicate slashes when the parameter is not provided
      projectPath: { type: 'path', value: null, squash: true },
      projects: { type: 'path', value: null, squash: true },

      // Allow passing of flash messages after routes load
      flash_message: { dynamic: true, value: null, inherit: false }
    }
  },
  {
    name: 'boards.**',
    parent: 'root',
    url: '/boards',
    loadChildren: () => import('../boards/openproject-boards.module').then(m => m.OpenprojectBoardsModule)
  },
  {
    name: 'bim.**',
    parent: 'root',
    url: '/bcf',
    loadChildren: () => import('../bim/ifc_models/openproject-ifc-models.module').then(m => m.OpenprojectIFCModelsModule)
  },
];

/**
 * Add or remove a body class. Helper for ui-router body classes functionality
 *
 * @param className
 * @param action
 */
export function bodyClass(className:string[]|string|null|undefined, action:'add'|'remove' = 'add') {
  if (className) {
    if (Array.isArray(className)) {
      className.forEach((cssClass:string) => {
        document.body.classList[action](cssClass);
      });
    } else {
      document.body.classList[action](className);
    }
  }
}

export function updateMenuItem(menuItemClass:string|undefined, action:'add'|'remove' = 'add') {
  if (!menuItemClass) {
    return;
  }

  let menuItem = jQuery('#main-menu .' + menuItemClass)[0];

  if (!menuItem) {
    return;
  }

  // Update Class
  menuItem.classList[action]('selected');

  // Update accessibility label
  let menuItemTitle = (menuItem.getAttribute('title') || '').split(':').slice(-1)[0];
  if (action === 'add') {
    menuItemTitle = I18n.t('js.description_current_position') + menuItemTitle;
  }

  menuItem.setAttribute('title', menuItemTitle);
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
      is: (val:unknown) => typeof (val) === 'string',
      equals: (a:any, b:any) => _.isEqual(a, b),
    }
  );
}

export function initializeUiRouterListeners(injector:Injector) {
  const $transitions:TransitionService = injector.get(TransitionService);
  const stateService = injector.get(StateService);
  const notificationsService:NotificationsService = injector.get(NotificationsService);
  const currentProject:CurrentProjectService = injector.get(CurrentProjectService);
  const firstRoute:FirstRouteService = injector.get(FirstRouteService);
  const backRoutingService:BackRoutingService = injector.get(BackRoutingService);

  // Check whether we are running within our complete app, or only within some other bootstrapped
  // component
  let wpBase = document.querySelector(appBaseSelector);

  // Uncomment to trace route changes
  // const uiRouter = injector.get(UIRouter);
  // uiRouter.trace.enable();

  // Apply classes from bodyClasses in each state definition
  // This was defined as onEnter, onExit functions in each state before
  // but since AOT doesn't allow anonymous functions, we can't re-use them now.
  // The transition will only return the target state on `transition.to()`,
  // however the second parameter has the currently (e.g., parent) entering state chain.
  $transitions.onEnter({}, function (transition:Transition, state:StateDeclaration) {
    // Add body class when entering this state
    bodyClass(_.get(state, 'data.bodyClasses'), 'add');
    if (transition.from().data && _.get(state, 'data.menuItem') !== transition.from().data.menuItem) {
      updateMenuItem(_.get(state, 'data.menuItem'), 'add');
    }

    // Reset scroll position, mostly relevant for mobile
    window.scrollTo(0, 0);
  });

  $transitions.onExit({}, function (transition:Transition, state:StateDeclaration) {
    // Remove body class when leaving this state
    bodyClass(_.get(state, 'data.bodyClasses'), 'remove');
    if (transition.to().data && _.get(state, 'data.menuItem') !== transition.to().data.menuItem) {
      updateMenuItem(_.get(state, 'data.menuItem'), 'remove');
    }
  });

  $transitions.onStart({}, function (transition:Transition) {
    const $state = transition.router.stateService;
    const toParams = transition.params('to');
    const fromState = transition.from();
    const toState = transition.to();

    // Remove start_onboarding_tour param if set
    if (toParams.start_onboarding_tour && toState.name !== 'work-packages.partitioned.list') {
      const paramsCopy = Object.assign({}, transition.params());
      paramsCopy.start_onboarding_tour = undefined;
      return $state.target(transition.to(), paramsCopy);
    }

    // Set backRoute to know where we came from
    backRoutingService.sync(transition);

    // Reset profiler, if we're actually profiling
    const profiler:any = (window as any).MiniProfiler;
    profiler && profiler.pageTransition();

    const projectIdentifier = toParams.projectPath || currentProject.identifier;
    if (!toParams.projects && projectIdentifier) {
      const newParams = _.clone(toParams);
      _.assign(newParams, { projectPath: projectIdentifier, projects: 'projects' });
      return $state.target(toState, newParams, { location: 'replace' });
    }

    // Abort the transition and move to the url instead
    if (wpBase === null) {

      // Only move to the URL if we're not coming from an initial URL load
      // (cases like /work_packages/invalid/activity which render a 403 without frontend,
      // but trigger the ui-router state)
      const source = transition.options().source;

      // Get the current path and compare
      const path = window.location.pathname;
      const target = stateService.href(toState, toParams);

      if (target && path !== target) {
        window.location.href = target;
        return false;
      }
    }

    // Remove and add any body class definitions for entering
    // and exiting states.
    bodyClass(_.get(toState, 'data.bodyClasses'), 'add');

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

    return true;
  });
}
