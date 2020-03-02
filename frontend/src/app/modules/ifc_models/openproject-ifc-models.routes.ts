// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
import {Ng2StateDeclaration, UIRouter} from '@uirouter/angular';
import {IFCViewerPageComponent} from "core-app/modules/ifc_models/pages/viewer/ifc-viewer-page.component";
import {BCFContainerComponent} from "core-app/modules/ifc_models/bcf/container/bcf-container.component";
import {IFCViewerComponent} from "core-app/modules/ifc_models/ifc-viewer/ifc-viewer.component";
import {WorkPackagesBaseComponent} from "core-app/modules/work_packages/routing/wp-base/wp--base.component";
import {EmptyComponent} from "core-app/modules/ifc_models/empty/empty-component";
import {BcfSingleViewComponent} from "core-app/modules/ifc_models/bcf/single-view/bcf-single-view.component";
import {WorkPackageOverviewTabComponent} from "core-components/wp-single-view-tabs/overview-tab/overview-tab.component";
import {WorkPackageActivityTabComponent} from "core-components/wp-single-view-tabs/activity-panel/activity-tab.component";
import {WorkPackageRelationsTabComponent} from "core-components/wp-single-view-tabs/relations-tab/relations-tab.component";
import {WorkPackageWatchersTabComponent} from "core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component";
import {makeSplitViewRoutes} from "core-app/modules/work_packages/routing/split-view-routes.template";
import {WorkPackageSplitViewComponent} from "core-app/modules/work_packages/routing/wp-split-view/wp-split-view.component";



export const IFC_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'bim',
    parent: 'root',
    url: '/bcf?query_props&models',
    abstract: true,
    component: WorkPackagesBaseComponent,
    redirectTo: 'bim.partitioned.split',
    params: {
      // Use custom encoder/decoder that ensures validity of URL string
      query_props: {type: 'opQueryString', dynamic: true},
      models: {type: 'opQueryString', dynamic: true}
    }
  },
  {
    name: 'bim.partitioned',
    url: '',
    component: IFCViewerPageComponent,
    redirectTo: 'bim.partitioned.split',
  },
  {
    name: 'bim.partitioned.list',
    url: '/list',
    data: {
      partition: '-right-only'
    },
    reloadOnSearch: false,
    views: {
      'content-right': { component: BCFContainerComponent }
    }
  },
  {
    name: 'bim.partitioned.split',
    url: '/split',
    data: {
      partition: '-split'
    },
    reloadOnSearch: false,
    views: {
      'content-left': { component: IFCViewerComponent },
      'content-right': { component: BCFContainerComponent }
    }
  },
  {
    name: 'bim.partitioned.model',
    url: '/model',
    data: {
      partition: '-left-only'
    },
    reloadOnSearch: false,
    views: {
      // Retarget and by that override the grandparent views
      // https://ui-router.github.io/guide/views#relative-parent-state{
      'content-right@^': { component: EmptyComponent },
      'content-left': { component: IFCViewerComponent }
    }
  },
  /**
   * BCF SINGLE VIEW
   */
  ...makeSplitViewRoutes(
    'bim.prtitioned.list',
    undefined,
    BcfSingleViewComponent
  )
];
