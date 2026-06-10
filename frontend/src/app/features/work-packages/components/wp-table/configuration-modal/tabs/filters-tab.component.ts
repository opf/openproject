import { ChangeDetectionStrategy, Component, Injector, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  TabComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import {
  WorkPackageFiltersService,
} from 'core-app/features/work-packages/components/filters/wp-filters/wp-filters.service';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';

@Component({
  templateUrl: './filters-tab.component.html',
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-table-config-filters-tab',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WpTableConfigurationFiltersTabComponent implements TabComponent, OnInit {
  readonly injector = inject(Injector);
  readonly I18n = inject(I18nService);
  readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  readonly wpFiltersService = inject(WorkPackageFiltersService);

  public filters:QueryFilterInstanceResource[] = [];

  public eeShowBanners = false;

  public text = {
    columnsLabel: this.I18n.t('js.label_columns'),
    selectedColumns: this.I18n.t('js.description_selected_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),

    upsellRelationColumns: this.I18n.t('js.modals.upsell_relation_columns'),
    upsellRelationColumnsLink: this.I18n.t('js.modals.upsell_relation_columns_link'),
  };

  ngOnInit() {
    this.wpTableFilters
      .onReady()
      .then(() => this.filters = this.wpTableFilters.current);

    this.wpTableFilters.changes$().subscribe((filters) => {
      this.filters = this.wpTableFilters.current;
    });
  }

  public onSave() {
    if (this.filters) {
      this.wpTableFilters.replaceIfComplete(this.filters);
    }
  }
}
