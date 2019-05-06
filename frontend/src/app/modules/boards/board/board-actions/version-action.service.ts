import {Injectable} from "@angular/core";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {Board} from "core-app/modules/boards/board/board";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {FilterOperator} from "core-components/api/api-v3/api-v3-filter-builder";
import {VersionResource} from "core-app/modules/hal/resources/version-resource";
import {VersionDmService} from "core-app/modules/hal/dm-services/version-dm.service";

@Injectable()
export class BoardVersionActionService implements BoardActionService {

  constructor(protected pathHelper:PathHelperService,
              protected boardListService:BoardListsService,
              protected I18n:I18nService,
              protected versionDm:VersionDmService) {
  }

  public get localizedName() {
    return this.I18n.t('js.work_packages.properties.version');
  }

  /**
   * Returns the current filter value if any
   * @param query
   * @returns /api/v3/versions/:id if a version filter exists
   */
  public getFilterValue(query:QueryResource):string|undefined {
    const filter = _.find(query.filters, filter => filter.id === 'version');

    if (filter) {
      const value = filter.values[0] as string|HalResource;
      return (value instanceof HalResource) ? value.href! : value;
    }

    return;
  }

  public addActionQueries(board:Board):Promise<Board> {
    return this.getVersions()
      .then((results) =>
        Promise.all<unknown>(
          results.map((version:VersionResource) => {

            if (version.isDefault) {
              return this.addActionQuery(board, version);
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

    let filter = { version: {
      operator: '=' as FilterOperator,
      values: [value.id]
    }};

    return this.boardListService.addQuery(board, params, [filter]);
  }

  /**
   * Return available versions for new lists, given the list of active
   * queries in the board.
   *
   * @param board The board we're looking at
   * @param queries The active set of queries
   */
  public getAvailableValues(board:Board, queries:QueryResource[]):Promise<HalResource[]> {
    const active = new Set(
      queries.map(query => this.getFilterValue(query))
    );

    return this.getVersions()
      .then(results =>
        results.filter(version => !active.has(version.href!))
      );
  }

  private getVersions():Promise<VersionResource[]> {
    return this.versionDm
      .list()
      .then(collection => collection.elements);
  }
}
