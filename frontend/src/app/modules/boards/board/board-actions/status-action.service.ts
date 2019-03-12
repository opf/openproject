import {Injectable} from "@angular/core";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {Board} from "core-app/modules/boards/board/board";
import {StatusDmService} from "core-app/modules/hal/dm-services/status-dm.service";
import {StatusResource} from "core-app/modules/hal/resources/status-resource";
import {QueryFilterBuilder} from "core-components/api/api-v3/query-filter-builder";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Injectable()
export class BoardStatusActionService implements BoardActionService {

  private readonly v3 = this.pathHelper.api.v3;
  private queryFilterBuilder = new QueryFilterBuilder(this.v3);

  constructor(protected pathHelper:PathHelperService,
              protected boardListService:BoardListsService,
              protected I18n:I18nService,
              protected statusDm:StatusDmService) {
  }

  public get localizedName() {
    return this.I18n.t('js.work_packages.properties.status');
  }

  /**
   * Returns the current filter value if any
   * @param query
   * @returns /api/v3/status/:id if a status filter exists
   */
  public getFilterValue(query:QueryResource):string|undefined {
    const filter = _.find(query.filters, filter => filter.id === 'status');

    if (filter) {
      const value = filter.values[0] as string|HalResource;
      return (value instanceof HalResource) ? value.href! : value;
    }

    return;
  }

  public addActionQueries(board:Board):Promise<Board> {
    return this.getStatuses()
      .then((results) =>
        Promise.all<unknown>(
          results.map((status:StatusResource) => {
            if (status.isClosed) {
              return this.addActionQuery(board, status);
            }

            if (status.isDefault) {
              return this.addActionQuery(board, status);
            }

            return Promise.resolve(board);
          })
        )
          .then(() => board)
      );
  }

  public addActionQuery(board:Board, value:HalResource):Promise<Board> {
    let params:any = {
      name: value.name,
    };

    let filter = this.queryFilterBuilder.build(
      'status',
      '=',
      [{ href: this.v3.statuses.id(value.id).toString() }]
    );

    return this.boardListService.addQuery(board, params, [filter]);
  }

  /**
   * Return available statuses for new lists, given the list of active
   * queries in the board.
   *
   * @param board The board we're looking at
   * @param queries The active set of queries
   */
  public getAvailableValues(board:Board, queries:QueryResource[]):Promise<HalResource[]> {
    const active = new Set(
      queries.map(query => this.getFilterValue(query))
    );

    return this.getStatuses()
      .then(results =>
        results.filter(status => !active.has(status.href!))
      );
  }

  private getStatuses():Promise<StatusResource[]> {
    return this.statusDm
      .list()
      .then(collection => collection.elements);
  }
}
