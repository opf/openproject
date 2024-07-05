import { Component, Input, SimpleChanges } from '@angular/core';
import { WorkPackageTableConfiguration } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { ChartOptions } from 'chart.js';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';
import DataLabelsPlugin from 'chartjs-plugin-datalabels';

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
  selector: 'op-wp-embedded-graph',
  templateUrl: './wp-embedded-graph.html',
  styleUrls: ['./wp-embedded-graph.component.sass'],
})
export class WorkPackageEmbeddedGraphComponent {
  @Input() public datasets:WorkPackageEmbeddedGraphDataset[];

  @Input() public chartOptions:ChartOptions;

  @Input() chartType = 'bar';

  public configuration:WorkPackageTableConfiguration;

  public error:string|null = null;

  public chartHeight = '100%';

  public chartLabels:string[] = [];

  public chartData:ChartDataSet[] = [];

  public chartPlugins = [DataLabelsPlugin];

  public internalChartOptions:ChartOptions;

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
      const groups = (dataset.groups || []).map((group) => group.value) as any;
      return array.concat(groups);
    }, [])) as string[];

    const labelCountMaps = this.datasets.map((dataset) => {
      const countMap = (dataset.groups || []).reduce((hash, group) => ({
        ...hash,
        [group.value]: group.count,
      }), {} as any);

      return {
        label: dataset.label,
        data: uniqLabels.map((label) => countMap[label] || 0),
      };
    });

    uniqLabels = uniqLabels.map((label) => {
      if (label === null) {
        return this.i18n.t('js.placeholders.default');
      }
      return label;
    });

    this.setHeight();

    // keep the array in order to update the labels
    this.chartLabels.length = 0;
    this.chartLabels.push(...uniqLabels);
    this.chartData.length = 0;
    this.chartData.push(...labelCountMaps);
  }

  protected setChartOptions() {
    const bodyFontColor= getComputedStyle(document.body).getPropertyValue('--body-font-color');
    const gridLineColor= getComputedStyle(document.body).getPropertyValue('--borderColor-default');
    const backdropColor= getComputedStyle(document.body).getPropertyValue('--overlay-backdrop-bgColor');

    const defaults:ChartOptions = {
      color: bodyFontColor,
      responsive: true,
      maintainAspectRatio: false,
      indexAxis: this.chartType === 'horizontalBar' ? 'y' : 'x',
      scales: {
        r: {
          angleLines: {
            color: this.isRadarChart() ? gridLineColor : 'transparent',
          },
          grid: {
            color: this.isRadarChart() ? gridLineColor : 'transparent',
          },
          pointLabels: {
            color: this.isRadarChart() ? bodyFontColor : 'transparent',
          },
          ticks: {
            color: this.isRadarChart() ? bodyFontColor : 'transparent',
            backdropColor: this.isRadarChart() ? backdropColor : 'transparent',
          },
        },
        y: {
          ticks: {
            color: this.isBarChart() ? bodyFontColor : 'transparent',
          },
          grid: {
            color: this.isBarChart() ? gridLineColor : 'transparent',
          },
          border: {
            color: this.isBarChart() ? bodyFontColor : 'transparent',
          },
        },
        x: {
          ticks: {
            color: this.isBarChart() ? bodyFontColor : 'transparent',
          },
          grid: {
            color: this.isBarChart() ? gridLineColor : 'transparent',
          },
          border: {
            color: this.isBarChart() ? bodyFontColor : 'transparent',
          },
        },
      },
      plugins: {
        legend: {
          // Only display legends if more than one dataset is provided.
          display: this.datasets.length > 1,
        },
        datalabels: {
          anchor: 'center',
          align: this.chartType === 'bar' ? 'top' : 'center',
          color: bodyFontColor,
        },
      },
    };

    this.internalChartOptions = {
      ...defaults,
      ...this.chartOptions,
    };
  }

  public get hasDataToDisplay() {
    return this.chartData.length > 0 && this.chartData.some((set) => set.data.length > 0);
  }

  public get mappedChartType():string {
    return this.chartType === 'horizontalBar' ? 'bar' : this.chartType;
  }

  public get chartDescription():string {
    const chartDataDescriptions = _.map(this.chartLabels, (label, index) => {
      if (this.chartData.length === 1) {
        const allCount = this.chartData[0].data[index];
        return `${allCount} ${label}`;
      }
      const labelCounts = _.map(this.chartData, (dataset) => `${dataset.data[index]} ${dataset.label}`);
      return `${label}: ${labelCounts.join(', ')}`;
    });

    return chartDataDescriptions.join('; ');
  }

  private setHeight() {
    if (this.chartType === 'horizontalBar' && this.datasets && this.datasets[0]) {
      const labels:string[] = [];
      this.datasets.forEach((d) => d.groups!.forEach((g) => {
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

  private isBarChart() {
    return this.chartType === 'bar' || this.chartType === 'horizontalBar' || this.chartType === 'line';
  }

  private isRadarChart() {
    return this.chartType === 'radar' || this.chartType === 'polarArea';
  }
}
