import { Injectable } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { WpTableConfigurationDisplaySettingsTab } from 'core-components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import { TabInterface } from "core-components/wp-table/configuration-modal/tab-portal-outlet";
import { WpTableConfigurationColumnsTab } from "core-components/wp-table/configuration-modal/tabs/columns-tab.component";
import { WpTableConfigurationFiltersTab } from "core-components/wp-table/configuration-modal/tabs/filters-tab.component";
import { WpTableConfigurationSortByTab } from "core-components/wp-table/configuration-modal/tabs/sort-by-tab.component";
import { WpTableConfigurationTimelinesTab } from "core-components/wp-table/configuration-modal/tabs/timelines-tab.component";
import { WpTableConfigurationHighlightingTab } from "core-components/wp-table/configuration-modal/tabs/highlighting-tab.component";

@Injectable()
export class WpTableConfigurationService {

  protected _tabs:TabInterface[] = [
    {
      id: 'columns',
      name: this.I18n.t('js.label_columns'),
      componentClass: WpTableConfigurationColumnsTab,
    },
    {
      id: 'filters',
      name: this.I18n.t('js.work_packages.query.filters'),
      componentClass: WpTableConfigurationFiltersTab,
    },
    {
      id: 'sort-by',
      name: this.I18n.t('js.label_sort_by'),
      componentClass: WpTableConfigurationSortByTab,
    },
    {
      id: 'display-settings',
      name: this.I18n.t('js.work_packages.table_configuration.display_settings'),
      componentClass: WpTableConfigurationDisplaySettingsTab,
    },
    {
      id: 'highlighting',
      name: this.I18n.t('js.work_packages.table_configuration.highlighting'),
      componentClass: WpTableConfigurationHighlightingTab,
    },
    {
      id: 'timelines',
      name: this.I18n.t('js.timelines.gantt_chart'),
      componentClass: WpTableConfigurationTimelinesTab
    }
  ];

  constructor(readonly I18n:I18nService) {
  }

  public get tabs() {
    return this._tabs;
  }
}
