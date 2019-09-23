import {Component, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {WorkPackageFiltersService} from 'core-components/filters/wp-filters/wp-filters.service';
import {WorkPackageViewFiltersService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service';
import {QueryFilterInstanceResource} from "core-app/modules/hal/resources/query-filter-instance-resource";
import {BannersService} from "core-app/modules/common/enterprise/banners.service";

@Component({
  templateUrl: './filters-tab.component.html',
  selector: 'wp-table-config-filters-tab'
})
export class WpTableConfigurationFiltersTab implements TabComponent {

  public filters:QueryFilterInstanceResource[] = [];
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
              readonly wpTableFilters:WorkPackageViewFiltersService,
              readonly wpFiltersService:WorkPackageFiltersService,
              readonly bannerService:BannersService) {
  }

  ngOnInit() {
    this.eeShowBanners = this.bannerService.eeShowBanners;
    this.wpTableFilters
      .onReady()
      .then(() => this.filters = this.wpTableFilters.current);
  }

  public onSave() {
    if (this.filters) {
      this.wpTableFilters.replaceIfComplete(this.filters);
    }
  }
}
