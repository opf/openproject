import {Component, Inject, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {QueryGroupByResource} from 'core-app/modules/hal/resources/query-group-by-resource';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableSumService} from 'core-components/wp-fast-table/state/wp-table-sum.service';

@Component({
  templateUrl: './display-settings-tab.component.html'
})
export class WpTableConfigurationDisplaySettingsTab implements TabComponent {

  // Display mode
  public displayMode:'hierarchy'|'grouped'|'default' = 'default';

  // Grouping
  public currentGroup:QueryGroupByResource|undefined;
  public availableGroups:QueryGroupByResource[] = [];

  // Sums row display
  public displaySums:boolean = false;

  public text = {
    choose_mode: this.I18n.t('js.work_packages.table_configuration.choose_display_mode'),
    label_group_by: this.I18n.t('js.label_group_by'),
    title: this.I18n.t('js.label_group_by'),
    placeholder: this.I18n.t('js.placeholders.default'),
    please_select: this.I18n.t('js.placeholders.selection'),
    default: '— ' + this.I18n.t('js.work_packages.table_configuration.default'),
    display_sums: this.I18n.t('js.work_packages.query.display_sums'),
    display_sums_hint: '— ' + this.I18n.t('js.work_packages.table_configuration.display_sums_hint'),
    display_mode: {
      default: this.I18n.t('js.work_packages.table_configuration.default_mode'),
      grouped: this.I18n.t('js.work_packages.table_configuration.grouped_mode'),
      hierarchy: this.I18n.t('js.work_packages.table_configuration.hierarchy_mode'),
      hierarchy_hint: '— ' + this.I18n.t('js.work_packages.table_configuration.hierarchy_hint')
    }
  };

  constructor(readonly injector:Injector,
              readonly I18n:I18nService,
              readonly wpTableGroupBy:WorkPackageTableGroupByService,
              readonly wpTableHierarchies:WorkPackageTableHierarchiesService,
              readonly wpTableSums:WorkPackageTableSumService) {
  }

  public onSave() {
    // Update hierarchy state
    this.wpTableHierarchies.setEnabled(this.displayMode === 'hierarchy');

    // Update grouping state
    let group = this.displayMode === 'grouped' ? this.currentGroup : undefined;
    this.wpTableGroupBy.set(group);

    // Update sums state
    this.wpTableSums.setEnabled(this.displaySums);
  }

  public updateGroup(href:string) {
    this.displayMode = 'grouped';
    this.currentGroup = _.find(this.availableGroups, group => group.href === href);
  }

  ngOnInit() {
    if (this.wpTableHierarchies.isEnabled) {
      this.displayMode = 'hierarchy';
    } else if (this.wpTableGroupBy.current) {
      this.displayMode = 'grouped';
    }

    this.displaySums = this.wpTableSums.currentSum || false;

    this.wpTableGroupBy
      .onReady()
      .then(() => {
        this.availableGroups = _.sortBy(this.wpTableGroupBy.available, 'name');
        this.currentGroup = this.wpTableGroupBy.current;
      });
  }
}
