import { Component, ViewChild } from '@angular/core';
import { TabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

@Component({
  selector: 'op-wp-graph-configuration-filters-tab',
  templateUrl: './filters-tab.component.html',
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective], // TODO replace
})
export class WpGraphConfigurationFiltersTabComponent implements TabComponent {
  @ViewChild('tabInner', { static: true })
  tabInner:TabComponent;

  public onSave() {
    this.tabInner.onSave();
  }
}
