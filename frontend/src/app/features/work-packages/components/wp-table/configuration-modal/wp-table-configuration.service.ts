import { Injectable } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WpTableConfigurationDisplaySettingsTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import { TabInterface } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { WpTableConfigurationColumnsTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/columns-tab.component';
import { WpTableConfigurationFiltersTab } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/filters-tab.component';
import { WpTableConfigurationSortByTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import { WpTableConfigurationTimelinesTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/timelines-tab.component';
import { WpTableConfigurationHighlightingTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/highlighting-tab.component';
import { OpBaselineComponent } from 'core-app/features/work-packages/components/wp-baseline/baseline/baseline.component';
import { StateService } from '@uirouter/angular';

@Injectable()
export class WpTableConfigurationService {
  protected _tabs:TabInterface[] = [
    {
      id: 'columns',
      name: this.I18n.t('js.label_columns'),
      componentClass: WpTableConfigurationColumnsTabComponent,
    },
    {
      id: 'filters',
      name: this.I18n.t('js.work_packages.query.filters'),
      componentClass: WpTableConfigurationFiltersTab,
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

  constructor(
    readonly I18n:I18nService,
    readonly $state:StateService,
  ) {
  }

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
