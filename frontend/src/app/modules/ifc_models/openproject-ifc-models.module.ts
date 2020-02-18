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
import {NgModule} from "@angular/core";
import {IFCBaseViewComponent} from "core-app/modules/ifc_models/ifc-base-view/ifc-base-view.component";
import {OpenprojectWorkPackagesModule} from "core-app/modules/work_packages/openproject-work-packages.module";
import { Ng2StateDeclaration, UIRouterModule, UIRouter } from '@uirouter/angular';
import {IFCIndexPageComponent} from "core-app/modules/ifc_models/pages/index/ifc-index-page.component";
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import { IFCViewerComponent } from './ifc-viewer/ifc-viewer.component';

export const IFC_ROUTES:Ng2StateDeclaration[] = [
  // TODO: properly namespace the routes e.g. bim.something
  {
    name: 'bim_defaults',
    parent: 'root',
    url: '/ifc_models/defaults/',
    component: IFCIndexPageComponent
  },
  {
    name: 'bim_show',
    parent: 'root',
    url: '/ifc_models/{model_id:[0-9]+}/',
    component: IFCIndexPageComponent,
  }
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

@NgModule({
  imports: [
    OpenprojectCommonModule,
    OpenprojectWorkPackagesModule,
    UIRouterModule.forChild({
      states: IFC_ROUTES,
      config: uiRouterIFCConfiguration
    })
  ],
  providers: [
  ],
  declarations: [
    // Pages
    IFCIndexPageComponent,
    IFCBaseViewComponent,

    IFCViewerComponent
  ],
  exports: [
    IFCBaseViewComponent,
    IFCViewerComponent
  ],
  entryComponents: [
    IFCBaseViewComponent,
    IFCViewerComponent
  ]
})
export class OpenprojectIFCModelsModule {
}

