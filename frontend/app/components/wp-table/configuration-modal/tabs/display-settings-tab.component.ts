import {Component, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {QueryGroupByResource} from 'core-components/api/api-v3/hal-resources/query-group-by-resource.service';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableSumService} from 'core-components/wp-fast-table/state/wp-table-sum.service';

@Component({
  template: require('!!raw-loader!./display-settings-tab.component.html')
})
export class WpTableConfigurationDisplaySettingsTab implements TabComponent {

  readonly I18n = this.injector.get(I18nToken);
  readonly wpTableGroupBy = this.injector.get(WorkPackageTableGroupByService);
  readonly wpTableHierarchies = this.injector.get(WorkPackageTableHierarchiesService);
  readonly wpTableSums = this.injector.get(WorkPackageTableSumService);

  // Display mode
  public displayMode:'hierarchy'|'grouped'|'default' = 'default';

  // Grouping
  public currentGroup:QueryGroupByResource|null = null;
  public availableGroups:QueryGroupByResource[] = [];

  // Sums row display
  public displaySums:boolean = false;

  public text = {
    label_group_by: this.I18n.t('js.label_group_by'),
    title: this.I18n.t('js.label_group_by'),
    placeholder: this.I18n.t('js.placeholders.default'),
    please_select: this.I18n.t('js.placeholders.selection'),
    display_sums: this.I18n.t('js.work_packages.query.display_sums'),
    display_sums_hint: this.I18n.t('js.work_packages.table_configuration.display_sums_hint'),
    display_mode: {
      default: this.I18n.t('js.work_packages.table_configuration.default_mode'),
      grouped: this.I18n.t('js.work_packages.table_configuration.grouped_mode'),
      grouped_hint: this.I18n.t('js.work_packages.table_configuration.grouped_hint'),
      hierarchy: this.I18n.t('js.work_packages.table_configuration.hierarchy_mode'),
      hierarchy_hint: this.I18n.t('js.work_packages.table_configuration.hierarchy_hint')
    }
  };

  constructor(readonly injector:Injector) {
  }

  public onSave() {
    // Update hierarchy state
    this.wpTableHierarchies.setEnabled(this.displayMode === 'hierarchy');

    // Update grouping state
    let group = this.displayMode === 'grouped' ? this.currentGroup : null;
    this.wpTableGroupBy.set(group);

    // Update sums state
    this.wpTableSums.setEnabled(this.displaySums);
  }

  public updateGroup(href:string) {
    this.currentGroup = _.find(this.availableGroups, group => group.href === href) || null;
  }

  ngOnInit() {
    if (this.wpTableHierarchies.isEnabled) {
      this.displayMode = 'hierarchy';
    } else if (this.wpTableGroupBy.current) {
      this.displayMode = 'grouped';
    }

    this.displaySums = this.wpTableSums.currentSum;

    this.wpTableGroupBy
      .onReady()
      .then(() => {
        this.availableGroups = _.sortBy(this.wpTableGroupBy.available, 'name');
        this.currentGroup = this.wpTableGroupBy.current;
      });
  }
}
