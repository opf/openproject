//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnDestroy, OnInit, inject } from '@angular/core';
import { WorkPackageEmbeddedGraphDataset } from 'core-app/shared/components/work-package-graphs/embedded/wp-embedded-graph.component';
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
  standalone: false,
})
export class WidgetWpGraphComponent extends AbstractWidgetComponent implements OnInit, OnDestroy {
  protected cdr = inject(ChangeDetectorRef);
  protected readonly graphConfiguration = inject(WpGraphConfigurationService);

  public datasets:WorkPackageEmbeddedGraphDataset[] = [];

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

  public get chartOptions():ChartOptions {
    return this.graphConfiguration.chartOptions;
  }

  public get chartType() {
    return this.graphConfiguration.chartType;
  }
}
