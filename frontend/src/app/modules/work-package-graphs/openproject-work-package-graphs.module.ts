//-- copyright
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { NgModule } from '@angular/core';
import { OpenprojectCommonModule } from 'core-app/modules/common/openproject-common.module';
import { OpenprojectModalModule } from "core-app/modules/modal/modal.module";
import { OpenprojectWorkPackagesModule } from "core-app/modules/work_packages/openproject-work-packages.module";
import { WpGraphConfigurationModalComponent } from "core-app/modules/work-package-graphs/configuration-modal/wp-graph-configuration.modal";
import { WpGraphConfigurationFiltersTab } from "core-app/modules/work-package-graphs/configuration-modal/tabs/filters-tab.component";
import { WpGraphConfigurationSettingsTab } from "core-app/modules/work-package-graphs/configuration-modal/tabs/settings-tab.component";
import { WpGraphConfigurationFiltersTabInner } from "core-app/modules/work-package-graphs/configuration-modal/tabs/filters-tab-inner.component";
import { WpGraphConfigurationSettingsTabInner } from "core-app/modules/work-package-graphs/configuration-modal/tabs/settings-tab-inner.component";
import { WorkPackageEmbeddedGraphComponent } from "core-app/modules/work-package-graphs/embedded/wp-embedded-graph.component";
import { WorkPackageOverviewGraphComponent } from "core-app/modules/work-package-graphs/overview/wp-overview-graph.component";
import { ChartsModule } from 'ng2-charts';
import * as ChartDataLabels from 'chartjs-plugin-datalabels';

@NgModule({
  imports: [
    // Commons
    OpenprojectCommonModule,
    OpenprojectModalModule,

    OpenprojectWorkPackagesModule,

    ChartsModule,
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
    WorkPackageOverviewGraphComponent,

  ],
  exports: [
    // Modals
    WpGraphConfigurationModalComponent,

    // Embedded graphs
    WorkPackageEmbeddedGraphComponent,
    WorkPackageOverviewGraphComponent
  ]
})
export class OpenprojectWorkPackageGraphsModule {
  constructor() {
    // By this seemingly useless statement, the plugin is registered with Chart.
    // Simply importing it will have it removed probably by angular tree shaking
    // so it will not be active. The current default of the plugin is to be enabled
    // by default. This will be changed in the future:
    // https://github.com/chartjs/chartjs-plugin-datalabels/issues/42
    ChartDataLabels;
  }
}
