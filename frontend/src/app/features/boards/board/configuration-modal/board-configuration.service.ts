import { Injectable, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TabInterface } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { BoardHighlightingTabComponent } from 'core-app/features/boards/board/configuration-modal/tabs/highlighting-tab.component';

@Injectable()
export class BoardConfigurationService {
  readonly I18n = inject(I18nService);

  protected _tabs:TabInterface[] = [
    {
      id: 'highlighting',
      name: this.I18n.t('js.work_packages.table_configuration.highlighting'),
      componentClass: BoardHighlightingTabComponent,
    },
  ];

  public get tabs() {
    return this._tabs;
  }
}
