// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  StateDeclaration,
  StateService,
  Transition,
  TransitionService,
  UIRouter,
} from '@uirouter/core';
import {
  IToast,
  ToastService,
} from 'core-app/shared/components/toaster/toast.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { Injector } from '@angular/core';
import { FirstRouteService } from 'core-app/core/routing/first-route-service';
import {
  Ng2StateDeclaration,
  StatesModule,
} from '@uirouter/angular';
import {
  appBaseSelector,
  ApplicationBaseComponent,
} from 'core-app/core/routing/base/application-base.component';
import { BackRoutingService } from 'core-app/features/work-packages/components/back-routing/back-routing.service';
import { MY_ACCOUNT_LAZY_ROUTES } from 'core-app/features/user-preferences/user-preferences.lazy-routes';
import { IAN_LAZY_ROUTES } from 'core-app/features/in-app-notifications/in-app-notifications.lazy-routes';
import { StateObject } from '@uirouter/core/lib/state/stateObject';
import {
  mobileGuardActivated,
  redirectToMobileAlternative,
} from 'core-app/shared/helpers/routing/mobile-guard.helper';
import { TEAM_PLANNER_LAZY_ROUTES } from 'core-app/features/team-planner/team-planner/team-planner.lazy-routes';
import { CALENDAR_LAZY_ROUTES } from 'core-app/features/calendar/calendar.lazy-routes';

export const OPENPROJECT_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'new_project.**',
    url: '/projects/new',
    loadChildren: () => import('../../features/projects/openproject-projects.module').then((m) => m.OpenprojectProjectsModule),
  },
  {
    name: 'root',
    abstract: true,
    url: '',
    component: ApplicationBaseComponent,
    params: {
      // Allow passing of flash messages after routes load
      flash_message: { dynamic: true, value: null, inherit: false },
    },
  },
  {
    name: 'optional_project',
    parent: 'root',
    url: '/{projects}/{projectPath}',
    abstract: true,
    params: {
      // value: null makes the parameter optional
      // squash: true avoids duplicate slashes when the parameter is not provided
      projectPath: { type: 'path', value: null, squash: true },
      projects: { type: 'path', value: null, squash: true },
    },
    views: {
      '!$default': { component: ApplicationBaseComponent },
    },
  },
  {
    name: 'api-docs.**',
    parent: 'optional_project',
    url: '/api/docs',
    loadChildren: () => import('../../features/api-docs/openproject-api-docs.module').then((m) => m.OpenprojectApiDocsModule),
  },
  {
    name: 'boards.**',
    parent: 'optional_project',
    url: '/boards',
    loadChildren: () => import('../../features/boards/openproject-boards.module').then((m) => m.OpenprojectBoardsModule),
  },
  {
    name: 'bim.**',
    parent: 'optional_project',
    url: '/bcf',
    loadChildren: () => import('../../features/bim/ifc_models/openproject-ifc-models.module').then((m) => m.OpenprojectIFCModelsModule),
  },
  {
    name: 'backlogs.**',
    parent: 'optional_project',
    url: '/backlogs',
    loadChildren: () => import('../../features/backlogs/openproject-backlogs.module').then((m) => m.OpenprojectBacklogsModule),
  },
  {
    name: 'backlogs_sprint.**',
    parent: 'optional_project',
    url: '/sprints',
    loadChildren: () => import('../../features/backlogs/openproject-backlogs.module').then((m) => m.OpenprojectBacklogsModule),
  },
  {
    name: 'reporting.**',
    parent: 'optional_project',
    url: '/cost_reports',
    loadChildren: () => import('../../features/reporting/openproject-reporting.module').then((m) => m.OpenprojectReportingModule),
  },
  {
    name: 'job-statuses.**',
    parent: 'optional_project',
    url: '/job_statuses',
    loadChildren: () => import('../../features/job-status/openproject-job-status.module').then((m) => m.OpenProjectJobStatusModule),
  },
  {
    name: 'project_settings.**',
    parent: 'optional_project',
    url: '/settings/general',
    loadChildren: () => import('../../features/projects/openproject-projects.module').then((m) => m.OpenprojectProjectsModule),
  },
  {
    name: 'project_copy.**',
    parent: 'optional_project',
    url: '/copy',
    loadChildren: () => import('../../features/projects/openproject-projects.module').then((m) => m.OpenprojectProjectsModule),
  },
  ...MY_ACCOUNT_LAZY_ROUTES,
  ...IAN_LAZY_ROUTES,
  ...TEAM_PLANNER_LAZY_ROUTES,
  ...CALENDAR_LAZY_ROUTES,
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

  const menuItem = jQuery(`#main-menu .${menuItemClass}`)[0];

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
    },
  );
}

export function initializeUiRouterListeners(injector:Injector) {
  const $transitions:TransitionService = injector.get(TransitionService);
  const stateService = injector.get(StateService);
  const toastService:ToastService = injector.get(ToastService);
  const currentProject:CurrentProjectService = injector.get(CurrentProjectService);
  const firstRoute:FirstRouteService = injector.get(FirstRouteService);
  const backRoutingService:BackRoutingService = injector.get(BackRoutingService);

  // Check whether we are running within our complete app, or only within some other bootstrapped
  // component
  const wpBase = document.querySelector(appBaseSelector);

  // Uncomment to trace route changes
  // const uiRouter = injector.get(UIRouter);
  // uiRouter.trace.enable();

  // For some pages it makes no sense to display them on mobile (e.g. the split screen).
  // If a `mobileAlternative` is specified, we redirect there instead.
  // Actually, this would be solved with an ActiveGuard, but unfortunately ui-router does not support this.
  // The recommended alternative is this transition hook (compare: https://github.com/angular-ui/ui-router/issues/2964)
  $transitions.onBefore(
    { to: (state) => (state ? mobileGuardActivated(state) : false) },
    (transition) => redirectToMobileAlternative(transition),
  );

  // Apply classes from bodyClasses in each state definition
  // This was defined as onEnter, onExit functions in each state before
  // but since AOT doesn't allow anonymous functions, we can't re-use them now.
  // The transition will only return the target state on `transition.to()`,
  // however the second parameter has the currently (e.g., parent) entering state chain.
  $transitions.onEnter({}, (transition:Transition, state:StateDeclaration) => {
    // Add body class when entering this state
    bodyClass(_.get(state, 'data.bodyClasses'), 'add');
    if (transition.from().data && _.get(state, 'data.menuItem') !== transition.from().data.menuItem) {
      updateMenuItem(_.get(state, 'data.menuItem'), 'add');
    }

    // Reset scroll position, mostly relevant for mobile
    window.scrollTo(0, 0);
  });

  $transitions.onExit({}, (transition:Transition, state:StateDeclaration) => {
    // Remove body class when leaving this state
    bodyClass(_.get(state, 'data.bodyClasses'), 'remove');
    if (transition.to().data && _.get(state, 'data.menuItem') !== transition.to().data.menuItem) {
      updateMenuItem(_.get(state, 'data.menuItem'), 'remove');
    }
  });

  $transitions.onStart({}, (transition:Transition) => {
    const $state = transition.router.stateService;
    const toParams = transition.params('to');
    const toState = transition.to();

    // Remove start_onboarding_tour param if set
    if (toParams.start_onboarding_tour && toState.name !== 'work-packages.partitioned.list') {
      const paramsCopy = { ...transition.params() };
      paramsCopy.start_onboarding_tour = undefined;
      return $state.target(transition.to(), paramsCopy);
    }

    // Set backRoute to know where we came from
    backRoutingService.sync(transition);

    // Reset profiler, if we're actually profiling
    const profiler:{ pageTransition:() => void }|undefined = window.MiniProfiler;
    profiler?.pageTransition();

    const toStateObject:StateObject|undefined = toState.$$state && toState.$$state();
    const hasProjectRoutes = toStateObject?.includes?.root;
    const projectIdentifier = toParams.projectPath as string || currentProject.identifier;
    if (hasProjectRoutes && !toParams.projects && projectIdentifier) {
      const newParams = _.clone(toParams);
      _.assign(newParams, { projectPath: projectIdentifier, projects: 'projects' });
      return $state.target(toState, newParams, { location: 'replace' });
    }

    // Abort the transition and move to the url instead
    // Only move to the URL if we're not coming from an initial URL load
    // (cases like /work_packages/invalid/activity which render a 403 without frontend,
    // but trigger the ui-router state)
    //
    // The FirstRoute service remembers the first angular route we went to
    // but for pages without any angular routes, this will stay empty.
    // So we also allow routes to happen after some delay
    if (wpBase === null) {
      // Get the current path and compare
      const path = window.location.pathname;
      const pathWithSearch = path + window.location.search;
      const target = stateService.href(toState, toParams);

      if (target && path !== target && pathWithSearch !== target) {
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
      toastService.clear();
    }

    // Add new notifications if passed to params
    if (toParams.flash_message) {
      toastService.add(toParams.flash_message as IToast);
    }

    return true;
  });
}
