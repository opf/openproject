import {Component, ElementRef, Input, OnInit, ViewChild} from '@angular/core';
import { WorkPackageTableConfigurationObject } from 'core-components/wp-table/wp-table-configuration';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {
  WorkPackageEmbeddedGraphComponent,
  WorkPackageEmbeddedGraphDataset
} from "core-components/wp-table/embedded/wp-embedded-graph.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'wp-by-version-graph',
  templateUrl: './wp-by-version-graph.template.html',
})

export class WorkPackageByVersionGraphComponent implements OnInit {
  @Input() versionId:number;
  @ViewChild('wpEmbeddedGraphMulti') private embeddedGraphMulti:WorkPackageEmbeddedGraphComponent;
  @ViewChild('wpEmbeddedGraphSingle') private embeddedGraphSingle:WorkPackageEmbeddedGraphComponent;
  public groupBy:string = 'status';
  public datasets:WorkPackageEmbeddedGraphDataset[] = [];
  public displayModeSingle = true;
  public availableGroupBy:{label:string, key:string}[];

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService) {
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
    this.datasets.length = 0;

    if (this.groupBy === 'status') {
      this.displayModeSingle = true;
      this.datasets.push({ label: this.I18n.t('js.label_all'), queryProps: this.propsBoth });
    } else {
      this.displayModeSingle = false;
      this.datasets.push({ label: this.I18n.t('js.label_open_work_packages'), queryProps: this.propsOpen });
      this.datasets.push({ label: this.I18n.t('js.label_closed_work_packages'), queryProps: this.propsClosed });
    }

    if (this.currentGraph) {
      this.currentGraph.tableState.refreshRequired.putValue([false, false], '');
    }
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
