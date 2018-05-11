import {Inject, Injectable, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {WpTableConfigurationDisplayModesTab} from 'core-components/wp-table/configuration-modal/tabs/display-modes-tab.component';
import {WpTableConfigurationColumnsTab} from 'core-components/wp-table/configuration-modal/tabs/columns-tab.component';
import {WpTableConfigurationSortByTab} from 'core-components/wp-table/configuration-modal/tabs/sort-by-tab.component';
import {WpTableConfigurationTimelinesTab} from 'core-components/wp-table/configuration-modal/tabs/timelines-tab.component';
import {WpTableConfigurationFiltersTab} from 'core-components/wp-table/configuration-modal/tabs/filters-tab.component';
import {WpTableConfigurationHighlightingTab} from 'core-components/wp-table/configuration-modal/tabs/highlighting-tab.component';

export interface WpTableConfigurationTabReference {
  name:string;
  title:string;
  disableBecause?:string;
  componentClass:{ new(...args:any[]):any };
}

@Injectable()
export class WpTableConfigurationService {

  protected _tabs:WpTableConfigurationTabReference[] = [
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
      name: 'display-modes',
      title: this.I18n.t('js.work_packages.table_configuration.display_modes'),
      componentClass: WpTableConfigurationDisplayModesTab,
    },
    {
      name: 'highlighting-modes',
      title: this.I18n.t('js.work_packages.table_configuration.highlighting'),
      componentClass: WpTableConfigurationHighlightingTab,
    },
    {
      name: 'timelines',
      title: this.I18n.t('js.timelines.gantt_chart'),
      componentClass: WpTableConfigurationTimelinesTab
    }
  ];

  constructor(@Inject(I18nToken) readonly I18n:op.I18n) {
  }

  public get tabs() {
    return this._tabs;
  }
}
