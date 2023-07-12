import { TabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { Component, ViewChild } from '@angular/core';

@Component({
  selector: 'op-wp-graph-configuration-settings-tab',
  templateUrl: './settings-tab.component.html',
})
export class WpGraphConfigurationSettingsTabComponent implements TabComponent {
  @ViewChild('tabInner', { static: true })
  tabInner:TabComponent;

  public onSave() {
    this.tabInner.onSave();
  }
}
