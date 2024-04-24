import { Inject, Injectable } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TabInterface } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { WpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.service';
import { QueryConfigurationLocals } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.component';
import { OpQueryConfigurationLocalsToken } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.constants';
import { StateService } from '@uirouter/angular';

@Injectable()
export class RestrictedWpTableConfigurationService extends WpTableConfigurationService {
  constructor(
    @Inject(OpQueryConfigurationLocalsToken) readonly locals:QueryConfigurationLocals,
    readonly I18n:I18nService,
    readonly $state:StateService,
  ) {
    super(I18n, $state);
  }

  public get tabs():TabInterface[] {
    const disabledTabs = this.locals.disabledTabs || {};

    return super
      .tabs
      .map((el) => {
        const reason = disabledTabs[el.id];
        if (reason != null) {
          el.disable = reason;
        }

        return el;
      });
  }
}
