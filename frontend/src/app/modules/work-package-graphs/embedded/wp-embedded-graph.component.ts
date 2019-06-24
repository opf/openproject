import {Component, Input, SimpleChanges} from '@angular/core';
import {WorkPackageTableConfiguration} from 'core-components/wp-table/wp-table-configuration';
import {GroupObject} from 'core-app/modules/hal/resources/wp-collection-resource';
import {Chart, ChartOptions, ChartType} from 'chart.js';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

export interface WorkPackageEmbeddedGraphDataset {
  label:string;
  queryProps:any;
  queryId?:number|string;
  groups?:GroupObject[];
}

@Component({
  selector: 'wp-embedded-graph',
  templateUrl: './wp-embedded-graph.html',
  styleUrls: ['./wp-embedded-graph.component.sass'],
})
export class WorkPackageEmbeddedGraphComponent {
  @Input() public datasets:WorkPackageEmbeddedGraphDataset[];
  @Input('chartOptions') public inputChartOptions:ChartOptions;
  @Input('chartType') chartType:ChartType = 'horizontalBar';

  public showTablePagination = false;
  public configuration:WorkPackageTableConfiguration;
  public error:string|null = null;

  public chartLabels:string[] = [];
  public chartData:any = [];
  public chartOptions:ChartOptions;

  constructor(readonly i18n:I18nService) {
  }

  ngOnChanges(changes:SimpleChanges) {
    if (changes.datasets) {
      this.setChartOptions();
      this.updateChartData();
    } else if (changes.chartType) {
      this.setChartOptions();
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
        return this.i18n.t('js.placeholders.default');
      } else {
        return label;
      }
    });

    // keep the array in order to update the labels
    this.chartLabels.length = 0;
    this.chartLabels.push(...uniqLabels);
    this.chartData.length = 0;
    this.chartData.push(...labelCountMaps);
  }

  protected setChartOptions() {
    let defaults = {
      responsive: true,
      maintainAspectRatio: false,
      legend: {
        // Only display legends if more than one dataset is provided.
        display: this.datasets.length > 1
      }
    };

    let chartTypeDefaults:ChartOptions = {};

    if (this.chartType === 'horizontalBar') {
      chartTypeDefaults = {
        scales: {
          xAxes: [{
            stacked: true,
            ticks: {
              callback: (value:number) => {
                if (Math.floor(value) === value) {
                  return value;
                } else {
                  return 0;
                }
              }
            }
          }],
            yAxes:
          [{
            stacked: true
          }]
        }
      };
    }

    this.chartOptions = Object.assign({}, defaults, chartTypeDefaults, this.inputChartOptions);
  }
}
