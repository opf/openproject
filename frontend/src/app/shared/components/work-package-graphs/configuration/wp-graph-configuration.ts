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

