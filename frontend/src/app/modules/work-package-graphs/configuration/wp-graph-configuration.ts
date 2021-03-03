import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { ChartType, ChartOptions } from 'chart.js';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";

export interface WpGraphQueryParams {
  id?:string;
  props?:any;
  name?:string;
}

export interface WpGraphConfiguration {
  queries:QueryResource[];
  queryParams:WpGraphQueryParams[];
  chartType:ChartType;
  chartOptions:ChartOptions;
}

export class WpGraphConfiguration implements WpGraphConfiguration {
  public queries:QueryResource[] = [];

  constructor(public queryParams:WpGraphQueryParams[],
              public chartOptions:ChartOptions,
              public chartType:ChartType) {
    this.chartType = this.chartType || 'horizontalBar';
  }

  public static queryCreationParams(i18n:I18nService, is_public:boolean) {
    return {
      hidden: true,
      public: is_public,
      name: i18n.t('js.grid.widgets.work_packages_graph.title'),
      showHierarchies: false,
      _links: {
        groupBy: {
          href: "/api/v3/queries/group_bys/status"
        }
      }
    };
  }
}
