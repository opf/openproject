import {Component, Inject, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {WorkPackageFiltersService} from 'core-components/filters/wp-filters/wp-filters.service';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableFilters} from 'core-components/wp-fast-table/wp-table-filters';

@Component({
  templateUrl: './filters-tab.component.html'
})
export class WpTableConfigurationFiltersTab implements TabComponent {

  public filters:WorkPackageTableFilters|undefined;
  public eeShowBanners:boolean = false;

  public text = {
    columnsLabel: this.I18n.t('js.label_columns'),
    selectedColumns: this.I18n.t('js.description_selected_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),

    upsaleRelationColumns: this.I18n.t('js.modals.upsale_relation_columns'),
    upsaleRelationColumnsLink: this.I18n.t('js.modals.upsale_relation_columns_link')
  };

  constructor(readonly injector:Injector,
              readonly I18n:I18nService,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpFiltersService:WorkPackageFiltersService) {
  }

  ngOnInit() {
    this.eeShowBanners = jQuery('body').hasClass('ee-banners-visible');
    this.wpTableFilters
      .onReady()
      .then(() => this.filters = this.wpTableFilters.currentState.$copy());
  }

  public onSave() {
    if (this.filters) {
      this.wpTableFilters.replaceIfComplete(this.filters);
    }
  }
}
