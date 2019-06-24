import {Component, ElementRef, Input, OnInit, ViewChild} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {
  WorkPackageEmbeddedGraphComponent,
  WorkPackageEmbeddedGraphDataset
} from "core-app/modules/work-package-graphs/embedded/wp-embedded-graph.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ChartOptions} from 'chart.js';
import {WpGraphConfigurationService} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration.service";
import {WpGraphConfiguration} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration";

@Component({
  selector: 'wp-by-version-graph',
  templateUrl: './wp-by-version-graph.template.html',
  styleUrls: ['./wp-by-version-graph.sass'],
  providers: [
    WpGraphConfigurationService
  ]
})

export class WorkPackageByVersionGraphComponent implements OnInit {
  @Input() versionId:number;
  @ViewChild('wpEmbeddedGraphMulti', { static: false }) private embeddedGraphMulti:WorkPackageEmbeddedGraphComponent;
  @ViewChild('wpEmbeddedGraphSingle', { static: false }) private embeddedGraphSingle:WorkPackageEmbeddedGraphComponent;
  public groupBy:string = 'status';
  public datasets:WorkPackageEmbeddedGraphDataset[] = [];
  public displayModeSingle = true;
  public availableGroupBy:{label:string, key:string}[];
  public chartOptions:ChartOptions = { maintainAspectRatio: true };

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly graphConfigurationService:WpGraphConfigurationService) {

    this.availableGroupBy = [{label: I18n.t('js.work_packages.properties.category'), key: 'category'},
                             {label: I18n.t('js.work_packages.properties.type'), key: 'type'},
                             {label: I18n.t('js.work_packages.properties.status'), key: 'status'},
                             {label: I18n.t('js.work_packages.properties.priority'), key: 'priority'},
                             {label: I18n.t('js.work_packages.properties.author'), key: 'author'},
                             {label: I18n.t('js.work_packages.properties.assignee'), key: 'assignee'}];
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.versionId = JSON.parse(element.getAttribute('version-id'));

    this.setQueryProps();
  }

  public setQueryProps() {
    this.datasets = [];

    let params = [];

    if (this.groupBy === 'status') {
      this.displayModeSingle = true;

      params.push({ name: this.I18n.t('js.label_all'), props: this.propsBoth });
    } else {
      this.displayModeSingle = false;

      params.push({ name: this.I18n.t('js.label_open_work_packages'), props: this.propsOpen });
      params.push({ name: this.I18n.t('js.label_closed_work_packages'), props: this.propsClosed });
    }

    this.graphConfigurationService.configuration = new WpGraphConfiguration(params, {}, 'horizontalBar');

    this.graphConfigurationService.reloadQueries().then(() => {
      this.datasets = this.graphConfigurationService.datasets;
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
    let filters = [{ version: { operator: '=', values: [this.versionId] }},
                   { subprojectId: { operator: '*', values: []}}];

    if (filter) {
      filters.push(filter);
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

DynamicBootstrapper.register({ selector: 'wp-by-version-graph', cls: WorkPackageByVersionGraphComponent });
