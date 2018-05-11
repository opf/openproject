import {Component, Inject, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {QueryGroupByResource} from 'core-app/modules/hal/resources/query-group-by-resource';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableSumService} from 'core-components/wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableHighlightingService, HighlightingMode} from 'core-components/wp-fast-table/state/wp-table-highlighting.service';

@Component({
  template: require('!!raw-loader!./highlighting-tab.component.html')
})
export class WpTableConfigurationHighlightingTab implements TabComponent {

  // Display mode
  public highlightingMode:HighlightingMode = 'default';

  public text = {
    title: this.I18n.t('js.work_packages.table_configuration.highlighting'),
    highlighting_mode: {
      description: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.description'),
      default: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.default'),
      default_text: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.default_text'),
      status: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.status'),
      status_text: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.status_text'),
      priority: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.priority'),
      priority_text: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.priority_text')
    }
  };

  constructor(readonly injector:Injector,
              @Inject(I18nToken) readonly I18n:op.I18n,
              readonly wpTableHighlight:WorkPackageTableHighlightingService) {
  }

  public onSave() {
    this.wpTableHighlight.update(this.highlightingMode);
  }

  public get selectedModeDescription() {
    switch (this.highlightingMode) {
      case 'priority':
        return this.text.highlighting_mode.priority_text;
      case 'status':
        return this.text.highlighting_mode.status_text;
      default:
        return this.text.highlighting_mode.default_text;
    }
  }

  ngOnInit() {
    this.highlightingMode = this.wpTableHighlight.current;
  }
}
