import {Component, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';

@Component({
  template: require('!!raw-loader!./display-settings-tab.component.html')
})
export class WpTableConfigurationDisplaySettingsTab  {

  readonly I18n = this.injector.get(I18nToken);
  public eeShowBanners:boolean = false;
  public text = {

    columnsLabel: this.I18n.t('js.label_columns'),
    selectedColumns: this.I18n.t('js.description_selected_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),

    upsaleRelationColumns: this.I18n.t('js.modals.upsale_relation_columns'),
    upsaleRelationColumnsLink: this.I18n.t('js.modals.upsale_relation_columns_link')
  };

  constructor(readonly injector:Injector) {

  }

  ngOnInit() {
    this.eeShowBanners = angular.element('body').hasClass('ee-banners-visible');
  }
}
