import {Injectable} from "@angular/core";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {QueryFormDmService} from "core-app/modules/hal/dm-services/query-form-dm.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {Board} from "core-app/modules/boards/board/board";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {QueryFilterBuilder} from "core-components/api/api-v3/query-filter-builder";

@Injectable()
export class BoardListsService {

  private readonly v3 = this.pathHelper.api.v3;
  private queryFilterBuilder = new QueryFilterBuilder(this.v3);

  constructor(private readonly CurrentProject:CurrentProjectService,
              private readonly pathHelper:PathHelperService,
              private readonly QueryDm:QueryDmService,
              private readonly halResourceService:HalResourceService,
              private readonly QueryFormDm:QueryFormDmService) {

  }

  private create(params:Object, filters:unknown[]):Promise<QueryResource> {
    return this.QueryFormDm
      .loadWithParams(
        {pageSize: 0},
        undefined,
        this.CurrentProject.identifier,
        this.buildQueryRequest(params, filters)
      )
      .then(form => {
        const query = this.QueryFormDm.buildQueryResource(form);
        return this.QueryDm.create(query, form);
      });
  }

  /**
   * Add a free query to the board
   */
  public addFreeQuery(board:Board, queryParams:Object) {
   const filter = this.queryFilterBuilder.build('manualSort', 'ow', []);
   return this.addQuery(board, queryParams, [filter]);
  }

  /**
   * Add an empty query to the board
   * @param board
   * @param query
   */
  public async addQuery(board:Board, queryParams:Object, filters:unknown[]):Promise<Board> {
    const count = board.queries.length;
    const query = await this.create(queryParams, filters);

    let source = {
      _type: 'GridWidget',
      identifier: 'work_package_query',
      startRow: 1,
      endRow: 2,
      startColumn: count + 1,
      endColumn: count + 2,
      options: {
        query_id: query.id
      }
    };

    let resource = this.halResourceService.createHalResourceOfClass(GridWidgetResource, source);
    board.addQuery(resource);

    return board;
  }

  private buildQueryRequest(params:Object, filters:unknown[]) {
    return {
      hidden: true,
      public: true,
      "_links": {
        "sortBy": [{"href": this.v3.resource("/queries/sort_bys/manualSorting-asc")}]
      },
      ...params,
      filters: filters
    };
  }
}

