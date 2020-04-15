import {Injectable} from "@angular/core";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {Board} from "core-app/modules/boards/board/board";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {FilterOperator} from "core-components/api/api-v3/api-v3-filter-builder";
import {CreateAutocompleterComponent} from "core-app/modules/common/autocomplete/create-autocompleter.component";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";
import {UserCacheService} from 'core-app/components/user/user-cache.service';
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {CurrentProjectService} from 'core-app/components/projects/current-project.service';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {AssigneeBoardHeaderComponent} from "core-app/modules/boards/board/board-actions/assignee/assignee-board-header.component";

@Injectable()
export class BoardAssigneeActionService implements BoardActionService {

  constructor(protected boardListsService:BoardListsService,
              protected I18n:I18nService,
              protected userCache:UserCacheService,
              protected halResourceService:HalResourceService,
              protected currentProject:CurrentProjectService
  ) {
  }

  public get localizedName() {
    return this.I18n.t('js.work_packages.properties.assignee');
  }

  /**
   * Returns the current filter value if any
   * @param query
   * @returns /api/v3/status/:id if a status filter exists
   */
  public getFilterHref(query:QueryResource):string|undefined {
    const filter = _.find(query.filters, filter => filter.id === 'assignee');
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
  public getLoadedFilterValue(query:QueryResource):Promise<undefined|UserResource> {
    const href = this.getFilterHref(query);

    if (href) {
      const id = HalResource.idFromLink(href);
      return this.userCache.require(id);
    } else {
      return Promise.resolve(undefined);
    }
  }

  public canAddToQuery(query:QueryResource):Promise<boolean> {
    return Promise.resolve(true);
  }

  public addActionQueries(board:Board):Promise<Board> {
    return Promise.resolve(board);
  }

  public addActionQuery(board:Board, value:HalResource):Promise<Board> {
    let params:any = {
      name: value.name,
    };

    let filter = {
      assignee: {
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
   * @param queries The active set of queries
   */
  public getAvailableValues(board:Board, queries:QueryResource[]):Promise<HalResource[]> {
    const active = new Set(
      queries.map(query => this.getFilterHref(query))
    );

    return this.getAssignees(board)
      .then(results =>
        results.filter(assignee => !active.has(assignee.href!))
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
    return AssigneeBoardHeaderComponent;
  }

  public disabledAddButtonPlaceholder(assignee:UserResource) {
    return undefined;
  }

  private getAssignees(board:Board):Promise<UserResource[]> {
    const projectIdentifier = this.currentProject.identifier!;
    let myData = this.halResourceService.get('/api/v3/projects/' + projectIdentifier + '/available_assignees').toPromise();


    return myData
      .then((collection:CollectionResource<UserResource>) => collection.elements);
  }

}
