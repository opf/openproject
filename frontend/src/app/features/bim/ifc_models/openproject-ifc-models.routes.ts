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

import { Ng2StateDeclaration } from '@uirouter/angular';
import { IFCViewerPageComponent } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-viewer-page.component';
import { makeSplitViewRoutes } from 'core-app/features/work-packages/routing/split-view-routes.template';
import { WorkPackageSplitViewComponent } from 'core-app/features/work-packages/routing/wp-split-view/wp-split-view.component';
import { WorkPackageNewFullViewComponent } from 'core-app/features/work-packages/components/wp-new/wp-new-full-view.component';
import { WorkPackagesBaseComponent } from 'core-app/features/work-packages/routing/wp-base/wp--base.component';
import { BcfSplitLeftComponent } from 'core-app/features/bim/ifc_models/bcf/split/left/bcf-split-left.component';
import { BcfSplitRightComponent } from 'core-app/features/bim/ifc_models/bcf/split/right/bcf-split-right.component';

export const sidemenuId = 'bim_sidemenu';

export const sideMenuOptions = {
  sidemenuId,
  hardReloadOnBaseRoute: true,
};

export const IFC_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'bim',
    parent: 'optional_project',
    url: '/bcf?query_id&query_props&models&viewpoint&name',
    abstract: true,
    component: WorkPackagesBaseComponent,
    redirectTo: 'bim.partitioned.list',
    params: {
      // Use custom encoder/decoder that ensures validity of URL string
      query_id: { type: 'query', dynamic: true },
      query_props: { type: 'opQueryString', dynamic: true },
      models: { type: 'opQueryString', dynamic: true },
      viewpoint: { type: 'int', dynamic: true },
      name: { type: 'string', dynamic: true },
    },
  },
  {
    name: 'bim.partitioned',
    redirectTo: 'bim.partitioned.list',
    url: '',
    component: IFCViewerPageComponent,
    data: {
      bodyClasses: 'router--bim',
      sideMenuOptions,
    },
  },
  {
    name: 'bim.partitioned.list',
    url: '',
    data: {
      baseRoute: 'bim.partitioned.list',
      newRoute: 'bim.partitioned.list.new',
      partition: '-split',
      sideMenuOptions,
    },
    reloadOnSearch: false,
    views: {
      'content-left': { component: BcfSplitLeftComponent },
      'content-right': { component: BcfSplitRightComponent },
    },
  },
  {
    name: 'bim.partitioned.new',
    url: '/new?type&parent_id',
    reloadOnSearch: false,
    data: {
      baseRoute: 'bim.partitioned.list',
      allowMovingInEditMode: true,
      partition: '-left-only',
      successState: 'bim.partitioned.show',
      sideMenuOptions,
    },
    views: { 'content-left': { component: WorkPackageNewFullViewComponent } },
  },
  {
    name: 'bim.partitioned.show',
    url: '/show/{workPackageId:[0-9]+}',
    data: {
      baseRoute: 'bim.partitioned.list',
      partition: '-left-only',
      sideMenuOptions,
    },
    reloadOnSearch: false,
    redirectTo: 'bim.partitioned.show.details',
  },
  // BCF full view detail routes for usage in revit addi-in
  ...makeSplitViewRoutes(
    'bim.partitioned.list',
    undefined,
    WorkPackageSplitViewComponent,
    undefined,
    true,
    false,
    'bim.partitioned.show',
  ),
  // BCF split view detail routes
  ...makeSplitViewRoutes(
    'bim.partitioned.list',
    undefined,
    WorkPackageSplitViewComponent,
    undefined,
    false,
    false,
  ),
];
