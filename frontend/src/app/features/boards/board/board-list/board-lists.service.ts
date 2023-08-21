import { Injectable } from '@angular/core';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Board } from 'core-app/features/boards/board/board';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import {
  firstValueFrom,
  Observable,
  switchMap,
} from 'rxjs';

@Injectable({ providedIn: 'root' })
export class BoardListsService {
  private v3 = this.pathHelper.api.v3;

  constructor(
    private readonly CurrentProject:CurrentProjectService,
    private readonly pathHelper:PathHelperService,
    private readonly apiV3Service:ApiV3Service,
    private readonly halResourceService:HalResourceService,
    private readonly toastService:ToastService,
    private readonly I18n:I18nService) {

  }

  private create(params:object, filters:ApiV3Filter[]):Observable<QueryResource> {
    const filterJson = JSON.stringify(filters);

    return this
      .apiV3Service
      .queries
      .form
      .loadWithParams(
        {
          pageSize: 0,
          filters: filterJson,
        },
        undefined,
        this.CurrentProject.identifier,
        this.buildQueryRequest(params),
      )
      .pipe(
        switchMap(([form, query]) => {
          // When the permission to create public queries is missing, throw an error.
          // Otherwise private queries would be created.
          if ((form.schema.public as IOPFieldSchema).writable) {
            return this
              .apiV3Service
              .queries
              .post(query, form);
          }
          throw new Error(this.I18n.t('js.boards.error_permission_missing'));
        }),
      );
  }

  /**
   * Add a free query to the board
   */
  public addFreeQuery(board:Board, queryParams:object) {
    const filter = this.freeBoardQueryFilter();
    return this.addQuery(board, queryParams, [filter]);
  }

  /**
   * Add an empty query to the board
   * @param board
   * @param query
   */
  public async addQuery(board:Board, queryParams:object, filters:ApiV3Filter[]):Promise<Board> {
    const count = board.queries.length;
    try {
      const query = await firstValueFrom(this.create(queryParams, filters));

      const source = {
        _type: 'GridWidget',
        identifier: 'work_package_query',
        startRow: 1,
        endRow: 2,
        startColumn: count + 1,
        endColumn: count + 2,
        options: {
          queryId: query.id,
          filters,
        },
      };

      const resource = this.halResourceService.createHalResourceOfClass(GridWidgetResource, source);
      board.addQuery(resource);
    } catch (e) {
      this.toastService.addError(e);
      console.error(e);
    }
    return board;
  }

  private buildQueryRequest(params:Object) {
    return {
      public: true,
      _links: {
        sortBy: [
          { href: `${this.v3.apiV3Base}/queries/sort_bys/manualSorting-asc` },
          { href: `${this.v3.apiV3Base}/queries/sort_bys/id-asc` },
        ],
      },
      ...params,
    };
  }

  private freeBoardQueryFilter():ApiV3Filter {
    return { manualSort: { operator: 'ow', values: [] } };
  }
}
