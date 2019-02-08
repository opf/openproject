import {Injectable} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {TabInterface} from "core-components/wp-table/configuration-modal/tab-portal-outlet";
import {BoardConfigurationDisplaySettingsTab} from "core-app/modules/boards/board/configuration-modal/tabs/display-settings-tab.component";

@Injectable()
export class BoardConfigurationService {

  protected _tabs:TabInterface[] = [
    {
      name: 'display',
      title: this.I18n.t('js.work_packages.table_configuration.display_settings'),
      componentClass: BoardConfigurationDisplaySettingsTab,
    }
  ];

  constructor(readonly I18n:I18nService) {
  }

  public get tabs() {
    return this._tabs;
  }
}
