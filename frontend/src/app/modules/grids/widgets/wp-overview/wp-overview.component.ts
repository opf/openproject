// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Component, ChangeDetectionStrategy, OnInit, ChangeDetectorRef} from '@angular/core';
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WpGraphConfigurationService} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration.service";
import {WorkPackageEmbeddedGraphDataset} from "core-app/modules/work-package-graphs/embedded/wp-embedded-graph.component";
import {ChartOptions} from 'chart.js';
import {WpGraphConfiguration} from "core-app/modules/work-package-graphs/configuration/wp-graph-configuration";

// TODO:
// * check if this can be replaced by the wp-by-version-graph component
// * ensure order of datasets: open first, closed second

@Component({
  templateUrl: './wp-overview.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    WpGraphConfigurationService
  ]
})
export class WidgetWpOverviewComponent extends AbstractWidgetComponent implements OnInit {
  public datasets:WorkPackageEmbeddedGraphDataset[] = [];

  constructor(protected readonly i18n:I18nService,
              protected readonly currentProject:CurrentProjectService,
              protected readonly graphConfigurationService:WpGraphConfigurationService,
              protected readonly cdr:ChangeDetectorRef) {
    super(i18n);
  }

  public get projectIdentifier() {
    return this.currentProject.identifier;
  }

  ngOnInit() {
    this.setQueryProps();
  }

  public setQueryProps() {
    this.datasets = [];
    let params = [];

    params.push({ name: this.i18n.t('js.label_open_work_packages'), props: this.propsOpen });
    params.push({ name: this.i18n.t('js.label_closed_work_packages'), props: this.propsClosed });

    this.graphConfigurationService.configuration = new WpGraphConfiguration(params, {}, 'horizontalBar');

    this.graphConfigurationService.reloadQueries().then(() => {
      this.datasets = this.graphConfigurationService.datasets;

      this.cdr.detectChanges();
    });
  }

  public get propsOpen() {
    return this.baseProps({status: { operator: 'o', values: []}});
  }

  public get propsClosed() {
    return this.baseProps({status: { operator: 'c', values: []}});
  }

  private baseProps(filter?:any) {
    let filters = [{ subprojectId: { operator: '*', values: []}}];

    if (filter) {
      filters.push(filter);
    }

    return {
      filters: JSON.stringify(filters),
      group_by: 'type',
      pageSize: 0
    };
  }
}
