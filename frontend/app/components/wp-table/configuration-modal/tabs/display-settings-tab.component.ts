import {Component, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {QueryGroupByResource} from 'core-components/api/api-v3/hal-resources/query-group-by-resource.service';

@Component({
  template: require('!!raw-loader!./display-settings-tab.component.html')
})
export class WpTableConfigurationDisplaySettingsTab implements TabComponent {

  readonly I18n = this.injector.get(I18nToken);
  readonly wpTableGroupBy = this.injector.get(WorkPackageTableGroupByService);

  // Grouping
  public currentGroup:QueryGroupByResource|null = null;
  public availableGroups:QueryGroupByResource[] = [];

  public text = {
    title: this.I18n.t('js.label_group_by'),
    placeholder: this.I18n.t('js.placeholders.default')
  };

  constructor(readonly injector:Injector) {
  }

  public onSave() {
    // Update grouping state
    this.wpTableGroupBy.set(this.currentGroup);
  }

  public updateGroup(href:string) {
    if (href === '') {
      this.currentGroup = null;
    } else {
      this.currentGroup = _.find(this.availableGroups, group => group.href === href)!;
    }
  }

  ngOnInit() {
    this.wpTableGroupBy
      .onReady()
      .then(() => {
        this.availableGroups = _.sortBy(this.wpTableGroupBy.available, 'name');
        this.currentGroup = this.wpTableGroupBy.current;
      });
  }
}
