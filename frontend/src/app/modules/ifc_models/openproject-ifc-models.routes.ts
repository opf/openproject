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

export const IFC_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'bim',
    parent: 'root',
    url: '/ifc_models?query_props',
    abstract: true,
    component: WorkPackagesBaseComponent,
    redirectTo: 'bim.partitioned.defaults',
    params: {
      // Use custom encoder/decoder that ensures validity of URL string
      query_props: {type: 'opQueryString', dynamic: true}
    }
  },
  {
    name: 'bim.partitioned',
    url: '',
    component: IFCViewerPageComponent
  },
  {
    name: 'bim.partitioned.list',
    url: '/list',
    data: {
      viewRoute: 'bim.partitioned.defaults',
      partition: '-right-only'
    },
    reloadOnSearch: false,
    views: {
      'content-right': { component: BCFContainerComponent }
    }
  },
  {
    name: 'bim.partitioned.defaults',
    url: '/defaults',
    data: {
      viewRoute: 'bim.partitioned.defaults',
      partition: '-split'
    },
    reloadOnSearch: false,
    views: {
      'content-left': { component: IFCViewerComponent },
      'content-right': { component: BCFContainerComponent }
    }
  },
  {
    name: 'bim.partitioned.defaults.model',
    url: '/model',
    data: {
      viewRoute: 'bim.partitioned.defaults',
      partition: '-left-only'
    },
    reloadOnSearch: false,
    views: {
      // Retarget and by that override the grandparent views
      // https://ui-router.github.io/guide/views#relative-parent-state
      'content-right@^.^': { component: EmptyComponent }
    }
  },
  {
    name: 'bim.partitioned.show',
    url: '/{model_id:[0-9]+}',
    data: {
      viewRoute: 'bim.partitioned.show',
      partition: '-split'
    },
    reloadOnSearch: false,
    views: {
      'content-left': { component: IFCViewerComponent },
      'content-right': { component: BCFContainerComponent }
    }
  },
  {
    name: 'bim.partitioned.show.model',
    url: '/model',
    data: {
      viewRoute: 'bim.partitioned.show',
      partition: '-left-only'
    },
    reloadOnSearch: false,
    views: {
      // Retarget and by that override the grandparent views
      // https://ui-router.github.io/guide/views#relative-parent-state
      'content-right@^.^': { component: EmptyComponent }
    }
  },
];
