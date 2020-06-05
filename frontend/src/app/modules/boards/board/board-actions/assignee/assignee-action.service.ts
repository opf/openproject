import {Injectable, Injector} from "@angular/core";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {Board} from "core-app/modules/boards/board/board";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {FilterOperator} from "core-components/api/api-v3/api-v3-filter-builder";
import {CreateAutocompleterComponent} from "core-app/modules/common/autocomplete/create-autocompleter.component";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {CurrentProjectService} from 'core-app/components/projects/current-project.service';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {AssigneeBoardHeaderComponent} from "core-app/modules/boards/board/board-actions/assignee/assignee-board-header.component";
import {input} from "reactivestates";
import {take} from "rxjs/operators";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {ProjectDmService} from "core-app/modules/hal/dm-services/project-dm.service";
import {ProjectResource} from "core-app/modules/hal/resources/project-resource";

@Injectable()
export class BoardAssigneeActionService implements BoardActionService {

  private assignees = input<HalResource[]>();

  @InjectField() public projectDmService:ProjectDmService;

  constructor(protected boardListsService:BoardListsService,
              protected I18n:I18nService,
              protected halResourceService:HalResourceService,
              protected pathHelper:PathHelperService,
              protected currentProject:CurrentProjectService,
              readonly injector:Injector) {
  }

  public get localizedName() {
    return this.I18n.t('js.work_packages.properties.assignee');
  }

  /**
   * Returns the current filter value if any
   * @param query
   * @returns /api/v3/assignee/:id if a assignee filter exists
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
   * Returns the loaded assignee
   * @param query
   */
  public getLoadedFilterValue(query:QueryResource):Promise<undefined|HalResource> {
    const href = this.getFilterHref(query);

    if (!href) {
      return Promise.resolve(undefined);
    }

    return this
      .getAssignees()
      .then(collection => collection.find(resource => resource.href === href));
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
   * Return available assignees for new lists, given the list of active
   * queries in the board.
   *
   * @param board The board we're looking at
   * @param active The active set of values (hrefs)
   */
  public getAvailableValues(board:Board, active:Set<string>):Promise<HalResource[]> {
    return this
      .getAssignees()
      .then(results =>
        results.filter(assignee => !active.has(assignee.id!))
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

  public disabledAddButtonPlaceholder(assignee:HalResource) {
    return undefined;
  }

  public warningTextWhenNoOptionsAvailable() {
    let text = this.I18n.t('js.boards.add_list_modal.warning.assignee');

    return this.projectDmService
      .one(parseInt(this.currentProject.id!))
      .then((project:ProjectResource) => {
        if (project.memberships) {
          text = text.concat(
            this.I18n.t('js.boards.add_list_modal.warning.add_members', {
              link: this.pathHelper.projectMembershipsPath(this.currentProject.identifier!)
            })
          );
        }

        return text;
      });
  }

  private getAssignees():Promise<HalResource[]> {
    const projectIdentifier = this.currentProject.identifier!;
    this.assignees.putFromPromiseIfPristine(() =>
      this.halResourceService
        .get(this.pathHelper.api.v3.projects.id(projectIdentifier).available_assignees)
        .toPromise()
        .then((collection:CollectionResource<UserResource>) => collection.elements)
    );

    return this.assignees
      .values$()
      .pipe(take(1))
      .toPromise();
  }

}
