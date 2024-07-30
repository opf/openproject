//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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

import { WorkPackageNewSplitViewComponent } from 'core-app/features/work-packages/components/wp-new/wp-new-split-view.component';
import { Ng2StateDeclaration } from '@uirouter/angular';
import { ComponentType } from '@angular/cdk/overlay';
import { WpTabWrapperComponent } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/wp-tab-wrapper.component';
import { WorkPackageCopySplitViewComponent } from 'core-app/features/work-packages/components/wp-copy/wp-copy-split-view.component';

/**
 * Return a set of routes for a split view mounted under the given base route,
 * which must be a grandchild of a PartitionedQuerySpacePageComponent.
 *
 * Example: base route = foo.bar
 *
 * Split view will be created at
 *
 * foo.bar.details
 * foo.bar.details.activity
 * foo.bar.details.relations
 * foo.bar.details.watchers
 *
 * NOTE: All parameters here must either be `export const` or literal strings,
 * otherwise AOT will not be able to look them up. This might result in missing routes.
 *
 * @param baseRoute The base route to mount under
 * @param showComponent The split view component to mount
 */
export function makeSplitViewRoutes(baseRoute:string,
  menuItemClass:string|undefined,
  showComponent:ComponentType<unknown>,
  newComponent:ComponentType<unknown> = WorkPackageNewSplitViewComponent,
  makeFullWidth?:boolean,
  showMobileAlternative = true,
  routeName = baseRoute):Ng2StateDeclaration[] {
  // makeFullWidth configuration
  const views:{ [content:string]:{ component:ComponentType<unknown>; }; } = makeFullWidth
    ? { 'content-left@^.^': { component: showComponent } }
    : { 'content-right@^.^': { component: showComponent } };
  const partition = makeFullWidth ? '-left-only' : '-split';

  return [
    {
      name: `${routeName}.details`,
      url: '/details/{workPackageId:[0-9]+}',
      redirectTo: (trans) => {
        const params = trans.params('to');
        return {
          state: `${routeName}.details.tabs`,
          params: { ...params, tabIdentifier: 'overview' },
        };
      },
      reloadOnSearch: false,
      data: {
        bodyClasses: 'router--work-packages-partitioned-split-view-details',
        menuItem: menuItemClass,
        // Remember the base route so we can route back to it anywhere
        baseRoute,
        newRoute: `${routeName}.new`,
        partition,
        mobileAlternative: showMobileAlternative ? 'work-packages.show' : undefined,
      },
      // Retarget and by that override the grandparent views
      // https://ui-router.github.io/guide/views#relative-parent-state
      views,
    },
    {
      name: `${routeName}.details.tabs`,
      url: '/:tabIdentifier',
      component: WpTabWrapperComponent,
      data: {
        baseRoute,
        menuItem: menuItemClass,
        parent: `${routeName}.details`,
        mobileAlternative: showMobileAlternative ? 'work-packages.show' : undefined,
      },
    },
    // Split create route
    {
      name: `${routeName}.new`,
      url: '/create_new?{type:[0-9]+}&{parent_id:[0-9]+}',
      reloadOnSearch: false,
      params: {
        defaults: {
          value: null,
        },
      },
      data: {
        partition: '-split',
        allowMovingInEditMode: true,
        bodyClasses: 'router--work-packages-partitioned-split-view-new',
        // Remember the base route so we can route back to it anywhere
        baseRoute,
        parent: baseRoute,
        mobileAlternative: showMobileAlternative ? 'work-packages.show' : undefined,
      },
      views: {
        // Retarget and by that override the grandparent views
        // https://ui-router.github.io/guide/views#relative-parent-state
        'content-right@^.^': { component: newComponent },
      },
    },
    // Split copy route
    {
      name: `${routeName}.copy`,
      url: '/details/{copiedFromWorkPackageId:[0-9]+}/copy',
      views: {
        'content-right@^.^': { component: WorkPackageCopySplitViewComponent },
      },
      reloadOnSearch: false,
      data: {
        baseRoute,
        parent: baseRoute,
        allowMovingInEditMode: true,
        bodyClasses: 'router--work-packages-partitioned-split-view',
        menuItem: menuItemClass,
        partition: '-split',
        mobileAlternative: showMobileAlternative ? 'work-packages.show' : undefined,
      },
    },
  ];
}
