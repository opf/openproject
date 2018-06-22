import {Injectable} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WpTableConfigurationDisplaySettingsTab} from 'core-components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import {WpTableConfigurationColumnsTab} from 'core-components/wp-table/configuration-modal/tabs/columns-tab.component';
import {WpTableConfigurationSortByTab} from 'core-components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import {WpTableConfigurationTimelinesTab} from 'core-components/wp-table/configuration-modal/tabs/timelines-tab.component';
import {WpTableConfigurationFiltersTab} from 'core-components/wp-table/configuration-modal/tabs/filters-tab.component';
import {TabInterface} from "core-components/wp-table/configuration-modal/tab-portal-outlet";

@Injectable()
export class WpTableConfigurationService {

  protected _tabs:TabInterface[] = [
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

  constructor(readonly I18n:I18nService) {
  }

  public get tabs() {
    return this._tabs;
  }
}
