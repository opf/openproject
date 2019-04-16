import {AfterViewInit, Component, Injector, Input, OnDestroy, OnInit, SimpleChanges} from '@angular/core';
import {WorkPackageTableConfiguration} from 'core-components/wp-table/wp-table-configuration';
import {GroupObject} from 'core-app/modules/hal/resources/wp-collection-resource';
import {Chart} from 'chart.js';
import {WorkPackageEmbeddedBaseComponent} from "core-components/wp-table/embedded/wp-embedded-base.component";

export interface WorkPackageEmbeddedGraphDataset {
  label:string;
  queryProps:any;
  queryId?:number;
  groups?:GroupObject[];
}

@Component({
  selector: 'wp-embedded-graph',
  templateUrl: './wp-embedded-graph.html'
})
export class WorkPackageEmbeddedGraphComponent extends WorkPackageEmbeddedBaseComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input() public datasets:WorkPackageEmbeddedGraphDataset[];

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

  ngOnChanges(changes:SimpleChanges) {
    if (this.initialized && (changes.datasets)) {
      this.loadQuery(false);
    }
  }

  private updateChartData() {
    let uniqLabels = _.uniq(this.datasets.reduce((array, dataset) => {
      let groups = (dataset.groups || []).map((group) => group.value) as any;
      return array.concat(groups);
    }, [])) as string[];

    let labelCountMaps = this.datasets.map((dataset) => {
      let countMap = (dataset.groups || []).reduce((hash, group) => {
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

  public loadQuery(visible:boolean = false) {
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
        this.updateChartData();
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
