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

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { ChartOptions } from 'chart.js';
import { I18nService } from 'core-app/core/i18n/i18n.service';

export interface WpGraphQueryParams {
  id?:string;
  props?:any;
  name?:string;
}

export interface WpGraphConfiguration {
  queries:QueryResource[];
  queryParams:WpGraphQueryParams[];
  chartType:string;
  chartOptions:ChartOptions;
}

export class WpGraphConfiguration implements WpGraphConfiguration {
  public queries:QueryResource[] = [];

  constructor(
    public queryParams:WpGraphQueryParams[],
    public chartOptions:ChartOptions,
    public chartType:string,
  ) {
    this.chartType = this.chartType || 'bar';
  }

  public static queryCreationParams(i18n:I18nService, isPublic:boolean):unknown {
    return {
      public: isPublic,
      name: i18n.t('js.grid.widgets.work_packages_graph.title'),
      showHierarchies: false,
      _links: {
        groupBy: {
          href: '/api/v3/queries/group_bys/status',
        },
      },
    };
  }
}

