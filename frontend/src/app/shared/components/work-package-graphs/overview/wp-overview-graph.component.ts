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

import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit, ViewChild, inject, input,
  booleanAttribute, model,
} from '@angular/core';
import {
  WorkPackageEmbeddedGraphComponent,
  WorkPackageEmbeddedGraphDataset,
} from 'core-app/shared/components/work-package-graphs/embedded/wp-embedded-graph.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ChartOptions } from 'chart.js';
import {
  WpGraphConfigurationService,
} from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration.service';
import {
  WpGraphConfiguration,
  WpGraphQueryParams,
} from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration';

type GraphFilter = Record<string, { operator:string; values:unknown[] }>;

@Component({
  selector: 'opce-wp-overview-graph',
  templateUrl: './wp-overview-graph.template.html',
  styleUrls: ['./wp-overview-graph.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    WpGraphConfigurationService,
  ],
  standalone: false,
})
export class WorkPackageOverviewGraphComponent implements OnInit {
  readonly elementRef = inject<ElementRef<Element>>(ElementRef);
  readonly I18n = inject(I18nService);
  readonly graphConfigurationService = inject(WpGraphConfigurationService);
  protected readonly cdr = inject(ChangeDetectorRef);

  // Rendered as a custom element, so inputs may arrive as attribute strings.
  readonly initialFilters = input<GraphFilter[]|null, string|GraphFilter[]|null>(null, {
    transform: (value) => (typeof value === 'string' ? JSON.parse(value) as GraphFilter[] : value),
  });

  readonly globalScope = input(false, { transform: booleanAttribute });

  @ViewChild('wpEmbeddedGraphMulti') private embeddedGraphMulti:WorkPackageEmbeddedGraphComponent;

  @ViewChild('wpEmbeddedGraphSingle') private embeddedGraphSingle:WorkPackageEmbeddedGraphComponent;

  readonly groupBy = model('status');

  readonly showGroupByOptions = input(true, { transform: booleanAttribute });

  readonly chartOptions = input<ChartOptions>({ maintainAspectRatio: false });

  public datasets:WorkPackageEmbeddedGraphDataset[] = [];

  public displayModeSingle = true;

  public availableGroupBy:{ label:string, key:string }[];

  public error:string|null = null;

  constructor() {
    const I18n = this.I18n;

    this.availableGroupBy = [{ label: I18n.t('js.work_packages.properties.category'), key: 'category' },
      { label: I18n.t('js.work_packages.properties.type'), key: 'type' },
      { label: I18n.t('js.work_packages.properties.status'), key: 'status' },
      { label: I18n.t('js.work_packages.properties.priority'), key: 'priority' },
      { label: I18n.t('js.work_packages.properties.author'), key: 'author' },
      { label: I18n.t('js.work_packages.properties.assignee'), key: 'assignee' }];
  }

  ngOnInit() {
    this.setQueryProps();
  }

  public setQueryProps() {
    this.datasets = [];

    const params = this.graphParams;

    this.graphConfigurationService.configuration = new WpGraphConfiguration(params, {}, 'horizontalBar');
    this.graphConfigurationService.globalScope = this.globalScope();

    // 'finally' was not available yet so the code for the change detection is duplicated
    this
      .graphConfigurationService
      .reloadQueries()
      .then(() => {
        this.datasets = this.sortedDatasets(this.graphConfigurationService.datasets, params);

        this.cdr.detectChanges();
      })
      .catch(() => {
        this.error = this.I18n.t('js.chart.errors.could_not_load');

        this.cdr.detectChanges();
      });
  }

  public get graphParams() {
    const params = [];

    if (this.groupBy() === 'status') {
      this.displayModeSingle = true;

      params.push({ name: this.I18n.t('js.label_all'), props: this.propsBoth });
    } else {
      this.displayModeSingle = false;

      params.push({ name: this.I18n.t('js.label_open_work_packages'), props: this.propsOpen });
      params.push({ name: this.I18n.t('js.label_closed_work_packages'), props: this.propsClosed });
    }

    return params;
  }

  public sortedDatasets(datasets:WorkPackageEmbeddedGraphDataset[], params:WpGraphQueryParams[]) {
    const sortingArray = params.map((x) => x.name);

    return datasets.slice().sort((a, b) => sortingArray.indexOf(a.label) - sortingArray.indexOf(b.label));
  }

  public get propsBoth() {
    return this.baseProps();
  }

  public get propsOpen() {
    return this.baseProps({ status: { operator: 'o', values: [] } });
  }

  public get propsClosed() {
    return this.baseProps({ status: { operator: 'c', values: [] } });
  }

  private baseProps(filter?:GraphFilter) {
    const filters:GraphFilter[] = [];

    const initialFilters = this.initialFilters();
    if (initialFilters) {
      filters.push(...initialFilters);
    } else {
      filters.push({ subprojectId: { operator: '*', values: [] } });
    }

    if (filter) {
      filters.push(filter);
    }

    return {
      'columns[]': [],
      filters: JSON.stringify(filters),
      group_by: this.groupBy(),
      pageSize: 0,
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
    }
    return this.embeddedGraphMulti;
  }
}
