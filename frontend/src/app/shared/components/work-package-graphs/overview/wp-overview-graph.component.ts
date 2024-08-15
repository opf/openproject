import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Input,
  OnInit,
  ViewChild,
} from '@angular/core';
import {
  WorkPackageEmbeddedGraphComponent,
  WorkPackageEmbeddedGraphDataset,
} from 'core-app/shared/components/work-package-graphs/embedded/wp-embedded-graph.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ChartOptions } from 'chart.js';
import {
  WpGraphConfigurationService,
} from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration.service';
import {
  WpGraphConfiguration,
  WpGraphQueryParams,
} from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration';


@Component({
  selector: 'opce-wp-overview-graph',
  templateUrl: './wp-overview-graph.template.html',
  styleUrls: ['./wp-overview-graph.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    WpGraphConfigurationService,
  ],
})

export class WorkPackageOverviewGraphComponent implements OnInit {
  @Input() initialFilters:any;

  @Input() globalScope:boolean;

  @ViewChild('wpEmbeddedGraphMulti') private embeddedGraphMulti:WorkPackageEmbeddedGraphComponent;

  @ViewChild('wpEmbeddedGraphSingle') private embeddedGraphSingle:WorkPackageEmbeddedGraphComponent;

  @Input() groupBy = 'status';

  @Input() chartOptions:ChartOptions = { maintainAspectRatio: false };

  public datasets:WorkPackageEmbeddedGraphDataset[] = [];

  public displayModeSingle = true;

  public availableGroupBy:{ label:string, key:string }[];

  public error:string|null = null;

  constructor(
    readonly elementRef:ElementRef<Element>,
    readonly I18n:I18nService,
    readonly graphConfigurationService:WpGraphConfigurationService,
    protected readonly cdr:ChangeDetectorRef,
  ) {
    this.availableGroupBy = [{ label: I18n.t('js.work_packages.properties.category'), key: 'category' },
      { label: I18n.t('js.work_packages.properties.type'), key: 'type' },
      { label: I18n.t('js.work_packages.properties.status'), key: 'status' },
      { label: I18n.t('js.work_packages.properties.priority'), key: 'priority' },
      { label: I18n.t('js.work_packages.properties.author'), key: 'author' },
      { label: I18n.t('js.work_packages.properties.assignee'), key: 'assignee' }];
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    this.initialFilters = JSON.parse(element.getAttribute('initial-filters') || 'null');
    this.globalScope = element.getAttribute('global-scope') === 'true';

    this.setQueryProps();
  }

  public setQueryProps() {
    this.datasets = [];

    const params = this.graphParams;

    this.graphConfigurationService.configuration = new WpGraphConfiguration(params, {}, 'horizontalBar');
    this.graphConfigurationService.globalScope = this.globalScope;

    // 'finally' was not available yet so the code for the change detection is duplicated
    this
      .graphConfigurationService
      .reloadQueries()
      .then(() => {
        this.datasets = this.sortedDatasets(this.graphConfigurationService.datasets, params);

        this.cdr.detectChanges();
      })
      .catch(() => {
        this.error = this.I18n.t('js.chart.errors.could_not_load');

        this.cdr.detectChanges();
      });
  }

  public get graphParams() {
    const params = [];

    if (this.groupBy === 'status') {
      this.displayModeSingle = true;

      params.push({ name: this.I18n.t('js.label_all'), props: this.propsBoth });
    } else {
      this.displayModeSingle = false;

      params.push({ name: this.I18n.t('js.label_open_work_packages'), props: this.propsOpen });
      params.push({ name: this.I18n.t('js.label_closed_work_packages'), props: this.propsClosed });
    }

    return params;
  }

  public sortedDatasets(datasets:WorkPackageEmbeddedGraphDataset[], params:WpGraphQueryParams[]) {
    const sortingArray = params.map((x) => x.name);

    return datasets.slice().sort((a, b) => sortingArray.indexOf(a.label) - sortingArray.indexOf(b.label));
  }

  public get propsBoth() {
    return this.baseProps();
  }

  public get propsOpen() {
    return this.baseProps({ status: { operator: 'o', values: [] } });
  }

  public get propsClosed() {
    return this.baseProps({ status: { operator: 'c', values: [] } });
  }

  private baseProps(filter?:any) {
    const filters = [];

    if (Array.isArray(this.initialFilters)) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      filters.push(...this.initialFilters);
    } else {
      filters.push({ subprojectId: { operator: '*', values: [] } });
    }

    if (filter) {
      filters.push(filter);
    }

    return {
      'columns[]': [],
      filters: JSON.stringify(filters),
      group_by: this.groupBy,
      pageSize: 0,
    };
  }

  public get displaySingle() {
    return this.displayModeSingle;
  }

  public get displayMulti() {
    return !this.displayModeSingle;
  }

  private get currentGraph() {
    if (this.displaySingle) {
      return this.embeddedGraphSingle;
    }
    return this.embeddedGraphMulti;
  }
}
