import {Inject, Injectable, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {WpTableConfigurationDisplaySettingsTab} from 'core-components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import {WpTableConfigurationColumnsTab} from 'core-components/wp-table/configuration-modal/tabs/columns-tab.component';
import {WpTableConfigurationSortByTab} from 'core-components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import {WpTableConfigurationTimelinesTab} from 'core-components/wp-table/configuration-modal/tabs/timelines-tab.component';
import {WpTableConfigurationFiltersTab} from 'core-components/wp-table/configuration-modal/tabs/filters-tab.component';

export interface WpTableConfigurationTabReference {
  name:string;
  title:string;
  componentClass:{ new(...args:any[]):any };
}

@Injectable()
export class WpTableConfigurationService {

  public tabs:WpTableConfigurationTabReference[] = [
    {
      name: 'filters',
      title: this.I18n.t('js.work_packages.query.filters'),
      componentClass: WpTableConfigurationFiltersTab,
    },
    {
      name: 'sort-by',
      title: this.I18n.t('js.label_sort_by'),
      componentClass: WpTableConfigurationSortByTab,
    },
    {
      name: 'columns',
      title: this.I18n.t('js.label_columns'),
      componentClass: WpTableConfigurationColumnsTab,
    },
    {
      name: 'display-settings',
      title: this.I18n.t('js.work_packages.table_configuration.display_settings'),
      componentClass: WpTableConfigurationDisplaySettingsTab,
    },
    {
      name: 'timelines',
      title: this.I18n.t('js.timelines.gantt_chart'),
      componentClass: WpTableConfigurationTimelinesTab
    }
  ];

  constructor(readonly injector:Injector,
              @Inject(I18nToken) readonly I18n:op.I18n) {

  }
}
