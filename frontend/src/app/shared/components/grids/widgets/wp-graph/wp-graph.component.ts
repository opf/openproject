import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnDestroy, OnInit,
} from '@angular/core';
import { WorkPackageEmbeddedGraphDataset } from 'core-app/shared/components/work-package-graphs/embedded/wp-embedded-graph.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { ChartOptions } from 'chart.js';
import { WpGraphConfigurationService } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration.service';
import { WpGraphConfiguration } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration';

@Component({
  selector: 'widget-wp-graph',
  templateUrl: './wp-graph.component.html',
  styleUrls: ['../wp-table/wp-table.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [WpGraphConfigurationService],
})
export class WidgetWpGraphComponent extends AbstractWidgetComponent implements OnInit, OnDestroy {
  public datasets:WorkPackageEmbeddedGraphDataset[] = [];

  constructor(protected i18n:I18nService,
    protected injector:Injector,
    protected cdr:ChangeDetectorRef,
    protected readonly graphConfiguration:WpGraphConfigurationService) {
    super(i18n, injector);
  }

  ngOnInit() {
    this.initializeConfiguration();
    this.loadQueriesInitially();
  }

  public set chartType(type:string) {
    this.resource.options.chartType = type;
  }

  public updateGraph(config:any) {
    this.graphConfiguration.persistAndReload()
      .then(() => {
        this.repaint();

        if (this.resource.options.chartType !== this.graphConfiguration.chartType) {
          const changeset = this.setChangesetOptions({ chartType: this.graphConfiguration.chartType });

          this.resourceChanged.emit(changeset);
        }
      });
  }

  protected repaint() {
    this.datasets = this.graphConfiguration.datasets;
    this.cdr.detectChanges();
  }

  protected initializeConfiguration() {
    const ids = [];
    if (this.resource.options.queryId) {
      ids.push({ id: this.resource.options.queryId as string });
    }

    this.graphConfiguration.configuration = new WpGraphConfiguration(
      ids,
      this.resource.options.chartOptions as ChartOptions,
      this.resource.options.chartType as string,
    );
  }

  protected loadQueriesInitially() {
    this.graphConfiguration.ensureQueryAndLoad()
      .then(() => {
        if (!this.resource.options.queryId) {
          const changeset = this.setChangesetOptions({ queryId: this.graphConfiguration.queryParams[0].id });

          this.resourceChanged.emit(changeset);
        }
        this.repaint();
      });
  }

  public get chartOptions() {
    return this.graphConfiguration.chartOptions;
  }

  public get chartType() {
    return this.graphConfiguration.chartType;
  }
}
