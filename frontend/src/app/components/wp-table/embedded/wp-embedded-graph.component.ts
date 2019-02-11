import {AfterViewInit, Component, Injector, Input, OnDestroy, OnInit, ViewChild} from '@angular/core';
import {CurrentProjectService} from 'core-components/projects/current-project.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {WorkPackageStatesInitializationService} from 'core-components/wp-list/wp-states-initialization.service';
import {WorkPackageTableRelationColumnsService} from 'core-components/wp-fast-table/state/wp-table-relation-columns.service';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableTimelineService} from 'core-components/wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableSortByService} from 'core-components/wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableSumService} from 'core-components/wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableAdditionalElementsService} from 'core-components/wp-fast-table/state/wp-table-additional-elements.service';
import { WorkPackageTableConfiguration } from 'core-components/wp-table/wp-table-configuration';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {LoadingIndicatorService} from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import {WorkPackageTableSelection} from 'core-components/wp-fast-table/state/wp-table-selection.service';
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {GroupObject} from 'core-app/modules/hal/resources/wp-collection-resource';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import { Chart } from 'chart.js';
import {WorkPackageEmbeddedBaseComponent} from "core-components/wp-table/embedded/wp-embedded-base.component";

export interface WorkPackageEmbeddedGraphDataset {
  label:string;
  queryProps:any;
  queryId?:number;
  groups?:GroupObject[];
}

@Component({
  selector: 'wp-embedded-graph',
  templateUrl: './wp-embedded-graph.html',
  providers: [
    TableState,
    OpTableActionsService,
    WorkPackageStatesInitializationService,
    WorkPackageTableRelationColumnsService,
    WorkPackageTablePaginationService,
    WorkPackageTableGroupByService,
    WorkPackageTableHierarchiesService,
    WorkPackageTableSortByService,
    WorkPackageTableColumnsService,
    WorkPackageTableFiltersService,
    WorkPackageTableTimelineService,
    WorkPackageTableSelection,
    WorkPackageTableSumService,
    WorkPackageTableAdditionalElementsService,
    WorkPackageTableRefreshService,
  ]
})

export class WorkPackageEmbeddedGraphComponent extends WorkPackageEmbeddedBaseComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input() public datasets:WorkPackageEmbeddedGraphDataset[];

  public tableInformationLoaded = false;
  public showTablePagination = false;
  public configuration:WorkPackageTableConfiguration;
  public error:string|null = null;

  public chartLabels:string[] = [];
  public chartData:any = [];
  public chartType:string = 'horizontalBar';
  public chartOptions = {
    responsive: true,
    scales: {
      xAxes: [{
        stacked: true,
        ticks: {
          callback: (value:number) => {
            if (Math.floor(value) === value) {
              return value;
            } else {
              return null;
            }
          }
        }
      }],
      yAxes: [{
        stacked: true
      }]
    }
  };

  constructor(injector:Injector) {
    super(injector);
  }

  public refresh(visible:boolean = true):Promise<any> {
    return super.refresh(visible).then(() => this.updateChartData());
  }

  private updateChartData() {
    let uniqLabels = _.uniq(this.datasets.reduce((array, dataset) => {
      return array.concat(dataset.groups!.map((group) => group.value) as any);
    }, [])) as string[];

    let labelCountMaps = this.datasets.map((dataset) => {
      let countMap = dataset.groups!.reduce((hash, group) => {
        hash[group.value] = group.count;
        return hash;
      }, {} as any);

      return {
        label: dataset.label,
        data: uniqLabels.map((label) => { return countMap[label] || 0; })
      };
    });

    uniqLabels = uniqLabels.map((label) => {
      if (!label) {
        return this.I18n.t('js.placeholders.default');
      } else {
        return label;
      }
    });

    // keep the array in order to update the labels
    this.chartLabels.length = 0;
    this.chartLabels.push(...uniqLabels);
    this.chartData = labelCountMaps;
  }

  protected loadQuery(visible:boolean = false) {
    this.error = null;

    let queries = this.datasets.map((dataset:any) => {
      return this.QueryDm
                 .find(
                   dataset.queryProps,
                   dataset.queryId,
                   this.queryProjectScope
                 )
                 .then(query => {
                   dataset.groups = query.results.groups;
                   return dataset;
                 })
        ;
    });

    const promise = Promise.all(queries)
      .then((datasets) => {
        this.setLoaded();
        return datasets;
      })
      .catch((error) => {
        this.error = this.I18n.t(
          'js.error.embedded_table_loading',
          { message: _.get(error, 'message', error) }
        );
      });

    if (visible) {
      this.loadingIndicator = promise;
    }

    return promise;
  }
}
