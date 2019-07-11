import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {Component, ViewChild} from "@angular/core";

@Component({
  templateUrl: './settings-tab.component.html'
})
export class WpGraphConfigurationSettingsTab implements TabComponent {
  @ViewChild('tabInner', { static: true })
  tabInner:TabComponent;

  public onSave() {
    this.tabInner.onSave();
  }
}
