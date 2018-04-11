import {Component, Inject, Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import WorkPackageFiltersService from 'core-components/filters/wp-filters/wp-filters.service';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';

@Component({
  template: require('!!raw-loader!./filters-tab.component.html')
})
export class WpTableConfigurationFiltersTab implements TabComponent {

  public filters = _.cloneDeep(this.wpTableFilters.currentState);
  public eeShowBanners:boolean = false;

  public text = {
    columnsLabel: this.I18n.t('js.label_columns'),
    selectedColumns: this.I18n.t('js.description_selected_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),

    upsaleRelationColumns: this.I18n.t('js.modals.upsale_relation_columns'),
    upsaleRelationColumnsLink: this.I18n.t('js.modals.upsale_relation_columns_link')
  };

  constructor(readonly injector:Injector,
              @Inject(I18nToken) readonly I18n:op.I18n,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpFiltersService:WorkPackageFiltersService) {
  }

  ngOnInit() {
    this.eeShowBanners = angular.element('body').hasClass('ee-banners-visible');
  }

  public onSave() {
  }
}
