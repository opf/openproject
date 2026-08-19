import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { WpGraphConfigurationService } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { QuerySpacedTabComponent } from 'core-app/shared/components/work-package-graphs/configuration-modal/tabs/abstract-query-spaced-tab.component';
import { WorkPackageFiltersService } from 'core-app/features/work-packages/components/filters/wp-filters/wp-filters.service';

@Component({
  selector: 'op-filters-tab-inner',
  templateUrl: './filters-tab-inner.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WpGraphConfigurationFiltersTabInnerComponent extends QuerySpacedTabComponent implements TabComponent, OnInit {
  readonly I18n:I18nService;
  readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  readonly wpFiltersService = inject(WorkPackageFiltersService);
  readonly wpStatesInitialization:WorkPackageStatesInitializationService;
  readonly wpGraphConfiguration:WpGraphConfigurationService;
  private cdRef = inject(ChangeDetectorRef);

  public filters:QueryFilterInstanceResource[] = [];

  public text = {
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),
  };

  constructor() {
    const I18n = inject(I18nService);
    const wpStatesInitialization = inject(WorkPackageStatesInitializationService);
    const wpGraphConfiguration = inject(WpGraphConfigurationService);

    super(I18n, wpStatesInitialization, wpGraphConfiguration);

    this.I18n = I18n;
    this.wpStatesInitialization = wpStatesInitialization;
    this.wpGraphConfiguration = wpGraphConfiguration;
  }

  ngOnInit() {
    void this.initializeQuerySpace()
      .then(() => {
        void this.wpTableFilters
          .onReady()
          .then(() => {
            this.filters = this.wpTableFilters.current;
            this.cdRef.markForCheck();
          });
      });
  }

  public onSave() {
    if (this.filters) {
      this.wpTableFilters.replaceIfComplete(this.filters);
      this.wpTableFilters.applyToQuery(this.wpGraphConfiguration.queries[0]);
    }
  }

  protected get query() {
    return this.wpGraphConfiguration.queries[0];
  }
}
