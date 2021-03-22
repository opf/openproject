import { Injectable } from "@angular/core";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { Board } from "core-app/modules/boards/board/board";
import { GridWidgetResource } from "core-app/modules/hal/resources/grid-widget-resource";
import { HalResourceService } from "core-app/modules/hal/services/hal-resource.service";
import { ApiV3Filter } from "core-components/api/api-v3/api-v3-filter-builder";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Injectable({ providedIn: 'root' })
export class BoardListsService {

  private v3 = this.pathHelper.api.v3;

  constructor(private readonly CurrentProject:CurrentProjectService,
              private readonly pathHelper:PathHelperService,
              private readonly apiV3Service:APIV3Service,
              private readonly halResourceService:HalResourceService,
              private readonly notifications:NotificationsService,
              private readonly I18n:I18nService) {

  }

  private create(params:Object, filters:ApiV3Filter[]):Promise<QueryResource> {
    const filterJson = JSON.stringify(filters);

    return this
      .apiV3Service
      .queries
      .form
      .loadWithParams(
        {
          pageSize: 0,
          filters: filterJson
        },
        undefined,
        this.CurrentProject.identifier,
        this.buildQueryRequest(params),
      )
      .toPromise()
      .then(([form, query]) => {
        // When the permission to create public queries is missing, throw an error.
        // Otherwise private queries would be created.
        if (form.schema['public'].writable) {
          return this
            .apiV3Service
            .queries
            .post(query, form)
            .toPromise();
        } else {
          throw new Error(this.I18n.t('js.boards.error_permission_missing'));
        }
      });
  }

  /**
   * Add a free query to the board
   */
  public addFreeQuery(board:Board, queryParams:Object) {
    const filter = this.freeBoardQueryFilter();
    return this.addQuery(board, queryParams, [filter]);
  }

  /**
   * Add an empty query to the board
   * @param board
   * @param query
   */
  public async addQuery(board:Board, queryParams:Object, filters:ApiV3Filter[]):Promise<Board> {
    const count = board.queries.length;
    try {
      const query = await this.create(queryParams, filters);

      const source = {
        _type: 'GridWidget',
        identifier: 'work_package_query',
        startRow: 1,
        endRow: 2,
        startColumn: count + 1,
        endColumn: count + 2,
        options: {
          queryId: query.id,
          filters: filters,
        }
      };

      const resource = this.halResourceService.createHalResourceOfClass(GridWidgetResource, source);
      board.addQuery(resource);
    } catch (e) {
      this.notifications.addError(e);
      console.error(e);
    }
    return board;
  }

  private buildQueryRequest(params:Object) {
    return {
      hidden: true,
      public: true,
      "_links": {
        "sortBy": [
          { "href": this.v3.apiV3Base + "/queries/sort_bys/manualSorting-asc" },
          { "href": this.v3.apiV3Base + "/queries/sort_bys/id-asc" },
        ]
      },
      ...params
    };
  }

  private freeBoardQueryFilter():ApiV3Filter {
    return { manualSort: { operator: 'ow', values: [] } };
  }
}
