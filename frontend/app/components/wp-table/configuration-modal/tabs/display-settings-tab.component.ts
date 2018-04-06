import {Component, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';

@Component({
  template: require('!!raw-loader!./display-settings-tab.component.html')
})
export class WpTableConfigurationDisplaySettingsTab implements TabComponent {

  readonly I18n = this.injector.get(I18nToken);

  const emptyOption = { title: I18n.t('js.inplace.clear_value_label') };

  public text = {
    title: this.I18n.t('js.label_group_by')
  };

  constructor(readonly injector:Injector) {

  }

  public onSave() {
  }

  ngOnInit() {
    this.eeShowBanners = angular.element('body').hasClass('ee-banners-visible');
  }
}
