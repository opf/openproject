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

import { NgModule } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { WpGraphConfigurationModalComponent } from 'core-app/shared/components/work-package-graphs/configuration-modal/wp-graph-configuration.modal';
import { WpGraphConfigurationFiltersTabComponent } from 'core-app/shared/components/work-package-graphs/configuration-modal/tabs/filters-tab.component';
import { WpGraphConfigurationSettingsTabComponent } from 'core-app/shared/components/work-package-graphs/configuration-modal/tabs/settings-tab.component';
import { WpGraphConfigurationFiltersTabInnerComponent } from 'core-app/shared/components/work-package-graphs/configuration-modal/tabs/filters-tab-inner.component';
import { WpGraphConfigurationSettingsTabInnerComponent } from 'core-app/shared/components/work-package-graphs/configuration-modal/tabs/settings-tab-inner.component';
import { WorkPackageEmbeddedGraphComponent } from 'core-app/shared/components/work-package-graphs/embedded/wp-embedded-graph.component';
import { WorkPackageOverviewGraphComponent } from 'core-app/shared/components/work-package-graphs/overview/wp-overview-graph.component';
import * as ChartDataLabels from 'chartjs-plugin-datalabels';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import { NgChartsModule } from 'ng2-charts';

@NgModule({
  imports: [
    // Commons
    OpSharedModule,
    OpenprojectModalModule,

    OpenprojectWorkPackagesModule,

    NgChartsModule,
    OpenprojectTabsModule,
  ],
  declarations: [
    // Modals
    WpGraphConfigurationModalComponent,
    WpGraphConfigurationFiltersTabComponent,
    WpGraphConfigurationFiltersTabInnerComponent,
    WpGraphConfigurationSettingsTabComponent,
    WpGraphConfigurationSettingsTabInnerComponent,

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
    WorkPackageOverviewGraphComponent,
  ],
})
export class OpenprojectWorkPackageGraphsModule {
  constructor() {
    // By this seemingly useless statement, the plugin is registered with Chart.
    // Simply importing it will have it removed probably by angular tree shaking
    // so it will not be active. The current default of the plugin is to be enabled
    // by default. This will be changed in the future:
    // https://github.com/chartjs/chartjs-plugin-datalabels/issues/42
    //
    // eslint-ignore-next-line @typescript-eslint/no-unused-expressions
    ChartDataLabels;
  }
}
