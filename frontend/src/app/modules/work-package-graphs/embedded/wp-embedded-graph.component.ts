import {Component, Input, SimpleChanges} from '@angular/core';
import {WorkPackageTableConfiguration} from 'core-components/wp-table/wp-table-configuration';
import {GroupObject} from 'core-app/modules/hal/resources/wp-collection-resource';
import {ChartOptions, ChartType} from 'chart.js';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

export interface WorkPackageEmbeddedGraphDataset {
  label:string;
  queryProps:any;
  queryId?:number|string;
  groups?:GroupObject[];
}
interface ChartDataSet {
  label:string;
  data:number[];
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

  public configuration:WorkPackageTableConfiguration;
  public error:string|null = null;

  public chartHeight = '100%';
  public chartLabels:string[] = [];
  public chartData:ChartDataSet[] = [];
  public chartOptions:ChartOptions;
  public initialized = false;

  public text = {
    noResults: this.i18n.t('js.work_packages.no_results.title'),
  };

  constructor(readonly i18n:I18nService) {}

  ngOnChanges(changes:SimpleChanges) {
    if (changes.datasets) {
      this.setChartOptions();
      this.updateChartData();


      if (!changes.datasets.firstChange) {
        this.initialized = true;
      }
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

    this.setHeight();

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
      },
      plugins: {
        datalabels: {
          align: this.chartType === 'bar' ? 'top' : 'center',
        }
      }
    };

    let chartTypeDefaults:ChartOptions = {scales:{}};
    if (this.chartType === 'horizontalBar' || this.chartType === 'bar' ) {
     this.setChartAxesValues(chartTypeDefaults);
    }

    this.chartOptions = Object.assign({}, defaults, chartTypeDefaults, this.inputChartOptions);
  }

  public get hasDataToDisplay() {
    return this.chartData.length > 0 && this.chartData.some(set => set.data.length > 0);
  }

  private setHeight() {
    if (this.chartType === 'horizontalBar' && this.datasets && this.datasets[0]) {
      let labels:string[] = [];
      this.datasets.forEach(d => d.groups!.forEach(g => {
        if (!labels.includes(g.value)) {
          labels.push(g.value);
        }
      }));
      let height = labels.length * 40;

      if (this.datasets.length > 1) {
        // make some more room for the legend
        height += 40;
      }

      // some minimum height e.g. for the labels
      height += 40;

      this.chartHeight = `${height}px`;
    } else {
      this.chartHeight = '100%';
    }
  }

  // function to set ticks of axis
  private setChartAxesValues(chartOptions:ChartOptions) {

    let changeableValuesAxis = [{
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
    }];

    let constantValuesAxis = [{
      stacked: true
    }];

    if (chartOptions.scales) {
      if (this.chartType === 'bar') {
        chartOptions.scales.yAxes = changeableValuesAxis;
        chartOptions.scales.xAxes = constantValuesAxis;
       } else if (this.chartType === 'horizontalBar') {
        chartOptions.scales.xAxes = changeableValuesAxis;
        chartOptions.scales.yAxes = constantValuesAxis;
      }
    }
  }
}
