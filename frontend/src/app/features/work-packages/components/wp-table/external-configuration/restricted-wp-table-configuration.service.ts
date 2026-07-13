import { Injectable, inject } from '@angular/core';
import { TabInterface } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { WpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.service';
import { QueryConfigurationLocals } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.component';
import { OpQueryConfigurationLocalsToken } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.constants';

@Injectable()
export class RestrictedWpTableConfigurationService extends WpTableConfigurationService {
  readonly locals = inject<QueryConfigurationLocals>(OpQueryConfigurationLocalsToken);

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
