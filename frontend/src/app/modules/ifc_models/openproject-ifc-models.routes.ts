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
import {IfcViewerPageComponent} from "core-app/modules/ifc_models/pages/viewer/ifc-viewer-page.component";
import {BcfContainerComponent} from "core-app/modules/ifc_models/bcf/container/bcf-container.component";
import {ApplicationBaseComponent} from "core-app/modules/router/base/application-base.component";
import {IFCViewerComponent} from "core-app/modules/ifc_models/ifc-viewer/ifc-viewer.component";

export const IFC_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'bim',
    parent: 'root',
    url: '/ifc_models',
    abstract: true,
    component: IfcViewerPageComponent
  },
  {
    name: 'bim.list',
    url: '/list',
    component: IfcViewerPageComponent,
    views: {
      right: { component: BcfContainerComponent }
    }
  },
  {
    name: 'bim.defaults',
    url: '/defaults',
    component: IfcViewerPageComponent,
    views: {
      left: { component: IFCViewerComponent }
    }
  },
  {
    name: 'bim.defaults.split',
    url: '/split',
    component: IfcViewerPageComponent,
    views: {
      left: { component: IFCViewerComponent },
      right: { component: BcfContainerComponent }
    }
  },
  {
    name: 'bim.show',
    url: '/{model_id:[0-9]+}',
    component: IfcViewerPageComponent,
    views: {
      left: { component: IfcViewerPageComponent }
    }
  },
  {
    name: 'bim.show.split',
    url: '/split',
    component: IfcViewerPageComponent,
    views: {
      left: { component: IFCViewerComponent },
      right: { component: BcfContainerComponent }
    }
  },
];

export function uiRouterIFCConfiguration(uiRouter:UIRouter) {
  uiRouter.urlService.rules
    .when(
      new RegExp("^/projects/(.*)/ifc_models/defaults$"),
      match => `/projects/${match[1]}/ifc_models/defaults/`
    );

  uiRouter.urlService.rules
    .when(
      new RegExp("^/projects/(.*)/ifc_models/([0-9]+)$"),
      match => `/projects/${match[1]}/ifc_models/${match[2]}/`
    );
}
