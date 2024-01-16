import { Injectable } from '@angular/core';
import { TabInterface } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { WpTableConfigurationTimelinesTabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tabs/timelines-tab.component';
import { WpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.service';

@Injectable()
export class WpTableWithGanttConfigurationService extends WpTableConfigurationService {
  protected _tabs:TabInterface[] = super.tabs.concat([
    {
      id: 'timelines',
      name: this.I18n.t('js.gantt_chart.label'),
      componentClass: WpTableConfigurationTimelinesTabComponent,
    },
  ]);
}
