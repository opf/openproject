import {Component, OnDestroy, OnInit} from '@angular/core';
import {WorkPackageEmbeddedGraphDataset} from "core-app/modules/work-package-graphs/embedded/wp-embedded-graph.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {ChartType, ChartOptions} from 'chart.js';
import {WpGraphConfigurationService} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration.service";
import {WpGraphConfiguration} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration";

@Component({
  selector: 'widget-wp-graph',
  templateUrl: './wp-graph.component.html',
  styleUrls: ['../wp-table/wp-table.component.sass',
              './wp-graph.component.sass'],
  providers: [WpGraphConfigurationService]
})
export class WidgetWpGraphComponent extends AbstractWidgetComponent implements OnInit, OnDestroy {
  public datasets:WorkPackageEmbeddedGraphDataset[] = [];

  constructor(protected i18n:I18nService,
              protected urlParamsHelper:UrlParamsHelperService,
              protected readonly graphConfiguration:WpGraphConfigurationService) {
    super(i18n);
  }

  ngOnInit() {
    this.initializeConfiguration();
    this.loadQueriesInitially();
  }

  ngOnDestroy() {
    // nothing to do
  }

  public set chartType(type:ChartType) {
    this.resource.options.chartType = type;
  }

  public updateGraph(config:any) {
    this.graphConfiguration.persistAndReload()
      .then(() => {
        this.updateDatasets();

        if (this.resource.options.chartType !== this.graphConfiguration.chartType) {
          this.resource.options.chartType = this.graphConfiguration.chartType;

          this.resourceChanged.emit(this.resource);
        }
      });
  }

  protected updateDatasets() {
    this.datasets = this.graphConfiguration.datasets;
  }

  protected initializeConfiguration() {
    let ids = [];
    if (this.resource.options.queryId) {
      ids.push({id: this.resource.options.queryId as string});
    }

    this.graphConfiguration.configuration = new WpGraphConfiguration(ids,
                                                                     this.resource.options.chartOptions as ChartOptions,
                                                                     this.resource.options.chartType as ChartType);
  }

  protected loadQueriesInitially() {
    this.graphConfiguration.ensureQueryAndLoad()
      .then(() => {
        if (!this.resource.options.queryId) {
          this.resource.options.queryId = this.graphConfiguration.queryParams[0].id;
          this.resourceChanged.emit(this.resource);
        }
        this.updateDatasets();
      });
  }

  public get chartOptions() {
    return this.graphConfiguration.chartOptions;
  }

  public get chartType() {
    return this.graphConfiguration.chartType;
  }
}
