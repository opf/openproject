import { Component, ViewChild } from '@angular/core';
import { TabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';

@Component({
  templateUrl: './filters-tab.component.html',
})
export class WpGraphConfigurationFiltersTabComponent implements TabComponent {
  @ViewChild('tabInner', { static: true })
  tabInner:TabComponent;

  public onSave() {
    this.tabInner.onSave();
  }
}
