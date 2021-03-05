import { Component, ViewChild } from '@angular/core';
import { TabComponent } from 'core-components/wp-table/configuration-modal/tab-portal-outlet';

@Component({
  templateUrl: './filters-tab.component.html'
})
export class WpGraphConfigurationFiltersTab implements TabComponent {
  @ViewChild('tabInner', { static: true })
  tabInner:TabComponent;

  public onSave() {
    this.tabInner.onSave();
  }
}
