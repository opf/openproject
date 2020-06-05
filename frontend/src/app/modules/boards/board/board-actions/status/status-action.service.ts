import {Injectable} from "@angular/core";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {Board} from "core-app/modules/boards/board/board";
import {StatusDmService} from "core-app/modules/hal/dm-services/status-dm.service";
import {StatusResource} from "core-app/modules/hal/resources/status-resource";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {FilterOperator} from "core-components/api/api-v3/api-v3-filter-builder";
import {CreateAutocompleterComponent} from "core-app/modules/common/autocomplete/create-autocompleter.component";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";
import {StatusCacheService} from "core-components/statuses/status-cache.service";

@Injectable()
export class BoardStatusActionService implements BoardActionService {

  constructor(protected boardListsService:BoardListsService,
              protected I18n:I18nService,
              protected statusCache:StatusCacheService,
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
  public getFilterHref(query:QueryResource):string|undefined {
    const filter = _.find(query.filters, filter => filter.id === 'status');

    if (filter) {
      const value = filter.values[0] as string|HalResource;
      return (value instanceof HalResource) ? value.href! : value;
    }

    return;
  }

  /**
   * Returns the loaded status
   * @param query
   */
  public getLoadedFilterValue(query:QueryResource):Promise<undefined|StatusResource> {
    const href = this.getFilterHref(query);

    if (href) {
      const id = HalResource.idFromLink(href);
      return this.statusCache.require(id);
    } else {
      return Promise.resolve(undefined);
    }
  }

  public canAddToQuery(query:QueryResource):Promise<boolean> {
    return Promise.resolve(true);
  }

  public addActionQueries(board:Board):Promise<Board> {
    return this.getStatuses()
      .then((results) =>
        Promise.all<unknown>(
          results.map((status:StatusResource) => {

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

    let filter = {
      status: {
        operator: '=' as FilterOperator,
        values: [value.id]
      }
    };

    return this.boardListsService.addQuery(board, params, [filter]);
  }

  /**
   * Return available statuses for new lists, given the list of active
   * queries in the board.
   *
   * @param board The board we're looking at
   * @param active The active set of values (hrefs or plain values)
   */
  public getAvailableValues(board:Board, active:Set<string>):Promise<HalResource[]> {
    return this.getStatuses()
      .then(results =>
        results.filter(status => !active.has(status.id!))
      );
  }

  public getAdditionalListMenuItems(query:QueryResource):Promise<OpContextMenuItem[]> {
    return Promise.resolve([]);
  }

  dragIntoAllowed(query:QueryResource, value:HalResource|undefined) {
    return true;
  }

  public autocompleterComponent() {
    return CreateAutocompleterComponent;
  }

  public headerComponent() {
    return undefined;
  }

  public disabledAddButtonPlaceholder(status:StatusResource) {
    return undefined;
  }

  public warningTextWhenNoOptionsAvailable() {
    return Promise.resolve(this.I18n.t('js.boards.add_list_modal.warning.status'));
  }

  private getStatuses():Promise<StatusResource[]> {
    return this.statusDm
      .list()
      .then(collection => collection.elements);
  }

}
