import { TabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { Component, ViewChild } from '@angular/core';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

@Component({
  selector: 'op-wp-graph-configuration-settings-tab',
  templateUrl: './settings-tab.component.html',
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
})
export class WpGraphConfigurationSettingsTabComponent implements TabComponent {
  @ViewChild('tabInner', { static: true })
  tabInner:TabComponent;

  public onSave() {
    this.tabInner.onSave();
  }
}
