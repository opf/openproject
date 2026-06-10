import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { WpGraphConfigurationService } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { TabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { QuerySpacedTabComponent } from 'core-app/shared/components/work-package-graphs/configuration-modal/tabs/abstract-query-spaced-tab.component';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';

interface OpChartType {
  identifier:string;
  label:string;
  indexAxis?:'x'|'y';
}

@Component({
  selector: 'op-settings-tab-inner',
  templateUrl: './settings-tab-inner.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class WpGraphConfigurationSettingsTabInnerComponent extends QuerySpacedTabComponent implements TabComponent, OnInit {
  readonly I18n:I18nService;
  readonly wpTableGroupBy = inject(WorkPackageViewGroupByService);
  readonly wpStatesInitialization:WorkPackageStatesInitializationService;
  readonly wpGraphConfiguration:WpGraphConfigurationService;
  private cdRef = inject(ChangeDetectorRef);

  // Grouping
  public availableGroups:QueryGroupByResource[] = [];

  public availableChartTypes:OpChartType[];

  public currentChartType:OpChartType;

  public text = {
    group_by: this.I18n.t('js.chart.axis_criteria'),
    chart_type: this.I18n.t('js.chart.type'),
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

  public onSave() {
    this.wpGraphConfiguration.chartType = this.currentChartType.identifier;
    this.wpGraphConfiguration.queries.forEach((query) => {
      this.wpTableGroupBy.applyToQuery(query);
    });
  }

  public get currentGroup() {
    return this.wpTableGroupBy.current!;
  }

  public set currentGroup(value:QueryGroupByResource) {
    this.wpTableGroupBy.update(value);
  }

  ngOnInit() {
    void this
      .initializeQuerySpace()
      .then(() => {
        void this.wpTableGroupBy
          .onReady()
          .then(() => {
            this.initializeAvailableGroups();
            this.initializeAvailableChartType();
            this.cdRef.markForCheck();
          });
      });
  }

  private initializeAvailableGroups() {
    let { available } = this.wpTableGroupBy;
    // the object in current is not identical to one in available. We therefore
    // have to do this by hand to be able to just use ngModel later.
    const { current } = this.wpTableGroupBy;

    if (current) {
      available = available.filter((group) => group.id !== current.id);
      available = available.concat(current);
    }

    this.availableGroups = _.sortBy(available, 'name');
  }

  private initializeAvailableChartType() {
    this.availableChartTypes = _.sortBy([
      { identifier: 'horizontalBar', label: this.I18n.t('js.chart.types.horizontal_bar') },
      { identifier: 'bar', label: this.I18n.t('js.chart.types.bar') },
      { identifier: 'line', label: this.I18n.t('js.chart.types.line') },
      { identifier: 'pie', label: this.I18n.t('js.chart.types.pie') },
      { identifier: 'doughnut', label: this.I18n.t('js.chart.types.doughnut') },
      { identifier: 'radar', label: this.I18n.t('js.chart.types.radar') },
      { identifier: 'polarArea', label: this.I18n.t('js.chart.types.polar_area') },
    ], 'label');

    this.currentChartType = this.availableChartTypes.find((type) => type.identifier === this.wpGraphConfiguration.configuration.chartType) || this.availableChartTypes[0];
  }

  protected get query() {
    return this.wpGraphConfiguration.queries[0];
  }
}
