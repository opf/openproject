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

import {OpenprojectCommonModule} from 'core-app/modules/common/openproject-common.module';
import {NgModule} from '@angular/core';
import {OpenprojectWorkPackagesModule} from "core-app/modules/work_packages/openproject-work-packages.module";
import {WpGraphConfigurationModalComponent} from "core-app/modules/work-package-graphs/configuration-modal/wp-graph-configuration.modal";
import {WpGraphConfigurationFiltersTab} from "core-app/modules/work-package-graphs/configuration-modal/tabs/filters-tab.component";
import {WpGraphConfigurationSettingsTab} from "core-app/modules/work-package-graphs/configuration-modal/tabs/settings-tab.component";
import {WpGraphConfigurationFiltersTabInner} from "core-app/modules/work-package-graphs/configuration-modal/tabs/filters-tab-inner.component";
import {WpGraphConfigurationSettingsTabInner} from "core-app/modules/work-package-graphs/configuration-modal/tabs/settings-tab-inner.component";
import {WorkPackageEmbeddedGraphComponent} from "core-app/modules/work-package-graphs/embedded/wp-embedded-graph.component";
import {WorkPackageByVersionGraphComponent} from "core-app/modules/work-package-graphs/by-version/wp-by-version-graph.component";
import {ChartsModule} from 'ng2-charts';

@NgModule({
  imports: [
    // Commons
    OpenprojectCommonModule,

    OpenprojectWorkPackagesModule,

    ChartsModule,
  ],
  providers: [
  ],
  declarations: [
    // Modals
    WpGraphConfigurationModalComponent,
    WpGraphConfigurationFiltersTab,
    WpGraphConfigurationFiltersTabInner,
    WpGraphConfigurationSettingsTab,
    WpGraphConfigurationSettingsTabInner,

    // Embedded graphs
    WorkPackageEmbeddedGraphComponent,
    // Work package graphs on version page
    WorkPackageByVersionGraphComponent,

  ],
  entryComponents: [
    // Modals
    WpGraphConfigurationModalComponent,
    WpGraphConfigurationFiltersTab,
    WpGraphConfigurationSettingsTab,

    // Work package graphs on version page
    WorkPackageByVersionGraphComponent,
  ],
  exports: [
    // Modals
    WpGraphConfigurationModalComponent,

    // Embedded graphs
    WorkPackageEmbeddedGraphComponent,
  ]
})
export class OpenprojectWorkPackageGraphsModule {
}
