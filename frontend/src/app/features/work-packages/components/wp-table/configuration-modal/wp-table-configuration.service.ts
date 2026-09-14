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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WpTableConfigurationDisplaySettingsTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import { TabInterface } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { WpTableConfigurationColumnsTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/columns-tab.component';
import { WpTableConfigurationFiltersTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/filters-tab.component';
import { WpTableConfigurationSortByTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import { WpTableConfigurationTimelinesTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/timelines-tab.component';
import { WpTableConfigurationHighlightingTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/highlighting-tab.component';
import { OpBaselineComponent } from 'core-app/features/work-packages/components/wp-baseline/baseline/baseline.component';
import { StateService } from '@uirouter/angular';

@Injectable({ providedIn: 'root' })
export class WpTableConfigurationService {
  readonly I18n = inject(I18nService);
  readonly $state = inject(StateService);

  protected _tabs:TabInterface[] = [
    {
      id: 'columns',
      name: this.I18n.t('js.label_columns'),
      componentClass: WpTableConfigurationColumnsTabComponent,
    },
    {
      id: 'filters',
      name: this.I18n.t('js.work_packages.query.filters'),
      componentClass: WpTableConfigurationFiltersTabComponent,
    },
    {
      id: 'sort-by',
      name: this.I18n.t('js.label_sort_by'),
      componentClass: WpTableConfigurationSortByTabComponent,
    },
    {
      id: 'baseline',
      name: this.I18n.t('js.baseline.toggle_title'),
      componentClass: OpBaselineComponent,
    },
    {
      id: 'display-settings',
      name: this.I18n.t('js.work_packages.table_configuration.display_settings'),
      componentClass: WpTableConfigurationDisplaySettingsTabComponent,
    },
    {
      id: 'highlighting',
      name: this.I18n.t('js.work_packages.table_configuration.highlighting'),
      componentClass: WpTableConfigurationHighlightingTabComponent,
    },
  ];

  public get tabs() {
    if (this.$state.current.name?.includes('work-packages') || this.$state.current.name?.includes('bim')) {
      return this._tabs;
    }

    return this._tabs.concat([
      {
        id: 'timelines',
        name: this.I18n.t('js.gantt_chart.label'),
        componentClass: WpTableConfigurationTimelinesTabComponent,
      },
    ]);
  }
}
