import {Component, ElementRef, Input, OnInit, ViewChild, ChangeDetectorRef, ChangeDetectionStrategy} from '@angular/core';
import {
  WorkPackageEmbeddedGraphComponent,
  WorkPackageEmbeddedGraphDataset
} from "core-app/modules/work-package-graphs/embedded/wp-embedded-graph.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ChartOptions} from 'chart.js';
import {WpGraphConfigurationService} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration.service";
import {
  WpGraphConfiguration,
  WpGraphQueryParams
} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration";

export const wpOverviewGraphSelector = 'wp-overview-graph';

@Component({
  selector: wpOverviewGraphSelector,
  templateUrl: './wp-overview-graph.template.html',
  styleUrls: ['./wp-overview-graph.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    WpGraphConfigurationService
  ]
})

export class WorkPackageOverviewGraphComponent implements OnInit {
  @Input() additionalFilter:any;
  @ViewChild('wpEmbeddedGraphMulti') private embeddedGraphMulti:WorkPackageEmbeddedGraphComponent;
  @ViewChild('wpEmbeddedGraphSingle') private embeddedGraphSingle:WorkPackageEmbeddedGraphComponent;
  @Input() groupBy:string = 'status';
  @Input() chartOptions:ChartOptions = { maintainAspectRatio: false };
  public datasets:WorkPackageEmbeddedGraphDataset[] = [];
  public displayModeSingle = true;
  public availableGroupBy:{label:string, key:string}[];
  public error:string|null = null;

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly graphConfigurationService:WpGraphConfigurationService,
              protected readonly cdr:ChangeDetectorRef) {

    this.availableGroupBy = [{label: I18n.t('js.work_packages.properties.category'), key: 'category'},
                             {label: I18n.t('js.work_packages.properties.type'), key: 'type'},
                             {label: I18n.t('js.work_packages.properties.status'), key: 'status'},
                             {label: I18n.t('js.work_packages.properties.priority'), key: 'priority'},
                             {label: I18n.t('js.work_packages.properties.author'), key: 'author'},
                             {label: I18n.t('js.work_packages.properties.assignee'), key: 'assignee'}];
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.additionalFilter = JSON.parse(element.getAttribute('additional-filter'));

    this.setQueryProps();
  }

  public setQueryProps() {
    this.datasets = [];

    let params = this.graphParams;

    this.graphConfigurationService.configuration = new WpGraphConfiguration(params, {}, 'horizontalBar');

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
    let params = [];

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
    let sortingArray = params.map((x) => x.name );

    return datasets.slice().sort((a, b) => {
      return sortingArray.indexOf(a.label) - sortingArray.indexOf(b.label);
    });

  }

  public get propsBoth() {
    return this.baseProps();
  }

  public get propsOpen() {
    return this.baseProps({status: { operator: 'o', values: []}});
  }

  public get propsClosed() {
    return this.baseProps({status: { operator: 'c', values: []}});
  }

  private baseProps(filter?:any) {
    let filters = [{subprojectId: {operator: '*', values: []}}];

    if (filter) {
      filters.push(filter);
    }

    if (this.additionalFilter) {
      filters.push(this.additionalFilter);
    }

    return {
      'columns[]': [],
      filters: JSON.stringify(filters),
      group_by: this.groupBy,
      pageSize: 0
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
    } else {
      return this.embeddedGraphMulti;
    }

  }
}


