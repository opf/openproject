import {Inject, Injectable, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {WpTableConfigurationDisplaySettingsTab} from 'core-components/wp-table/configuration-modal/tabs/display-settings-tab.component';
import {WpTableConfigurationColumnsTab} from 'core-components/wp-table/configuration-modal/tabs/columns-tab.component';

export interface WpTableConfigurationTabReference {
  name:string;
  title:string;
  componentClass:{ new(injector:Injector):any };
}

@Injectable()
export class WpTableConfigurationService {

  public tabs:WpTableConfigurationTabReference[] = [
    {
      name: 'filters',
      title: this.I18n.t('js.work_packages.query.filters'),
      componentClass: WpTableConfigurationDisplaySettingsTab,
    },
    {
      name: 'columns',
      title: this.I18n.t('js.label_columns'),
      componentClass: WpTableConfigurationColumnsTab,
    },
    {
      name: 'display-settings',
      title: 'Display settings', // this.I18n.t('js.label_columns'),
      componentClass: WpTableConfigurationDisplaySettingsTab,
    }
  ];

  constructor(readonly injector:Injector,
              @Inject(I18nToken) readonly I18n:op.I18n) {

  }
}
