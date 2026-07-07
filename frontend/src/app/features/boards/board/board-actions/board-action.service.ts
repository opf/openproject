import { Board } from 'core-app/features/boards/board/board';
import { ComponentType } from '@angular/cdk/portal';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { DisabledButtonPlaceholder } from 'core-app/features/boards/board/board-list/board-list.component';
import { CreateAutocompleterComponent } from 'core-app/shared/components/autocompleter/create-autocompleter/create-autocompleter.component';
import { BoardListsService } from 'core-app/features/boards/board/board-list/board-lists.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { Injectable, Injector, inject } from '@angular/core';
import { map } from 'rxjs/operators';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { WorkPackageFilterValues } from 'core-app/features/work-packages/components/wp-edit-form/work-package-filter-values';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { Observable } from 'rxjs';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Injectable()
export abstract class BoardActionService {
  readonly injector = inject(Injector);
  protected boardListsService = inject(BoardListsService);
  protected I18n = inject(I18nService);
  protected halResourceService = inject(HalResourceService);
  protected pathHelper = inject(PathHelperService);
  protected currentProject = inject(CurrentProjectService);
  protected apiV3Service = inject(ApiV3Service);
  protected schemaCache = inject(SchemaCacheService);


  /**
   * Get the attribute name
   */
  localizedName:string;

  /**
   * The action filter name
   */
  filterName:string;

  /**
   * The action resource name for the autocompleter
   */
  resourceName:string;

  /**
   * The icon used in tile
   */
  icon:string;

  /**
   * The description used in tile
   */
  description:string;

  /**
   * The description used in tile
   */
  image:string;

  /**
   * Label used to describe the values in the modal
   */
  label:string;

  /**
   * The text used in tile header
   */
  text:string;

  /**
   * Returns the current filter instance
   * @param query
   */
  getActionFilter(query:QueryResource, getHref = false):QueryFilterInstanceResource|undefined {
    return query.filters.find((filter) => filter.id === this.filterName);
  }

  /**
   * Returns the current filter value ID if any
   * @param query
   * @returns The id of the resource
   */
  getActionValueId(query:QueryResource, getHref = false):string|undefined {
    const filter = this.getActionFilter(query);
    if (!filter) {
      return;
    }

    const value = filter.values[0];

    if (value instanceof HalResource) {
      return getHref ? value.href! : value.id!;
    }

    return value;
  }

  /**
   * Returns the current filter value if any
   * @param query
   * @returns The loaded action resource
   */
  getLoadedActionValue(query:QueryResource):Promise<HalResource|undefined> {
    const id = this.getActionValueId(query);

    if (!id) {
      return Promise.resolve(undefined);
    }

    return this.require(id);
  }

  /**
   * Add a single action query
   */
  addColumnWithActionAttribute(board:Board, value:HalResource):Promise<Board> {
    const params:any = {
      name: value.name,
    };

    const filter = {
      [this.filterName]: {
        operator: '=' as FilterOperator,
        values: [idFromLink(value.href)],
      },
    };

    return this.boardListsService.addQuery(board, params, [filter]);
  }

  /**
   * Get available values from the active queries
   *
   * @param board The board we're looking at
   * @param active The active set of values (resources or plain values)
   * @param matching values matching the given name
   */
  loadAvailable(active:Set<string>, matching:string):Observable<HalResource[]> {
    return this
      .loadValues(matching)
      .pipe(
        map((items) => items.filter((item) => !active.has(item.id!))),
      );
  }

  /**
   * Get action specific items that shall be shown in the list menu
   * @returns {any[]}
   */
  getAdditionalListMenuItems(query:QueryResource):Promise<OpContextMenuItem[]> {
    return Promise.resolve([]);
  }

  /**
   * Get the specific component for the autocompleter (e.g versionAutocompleter)
   * @returns {Component}
   */
  autocompleterComponent():ComponentType<unknown> {
    return CreateAutocompleterComponent;
  }

  /**
   * Get the specific header component for the board list, or undefined if none
   * @returns {Component}
   */
  headerComponent():ComponentType<unknown>|undefined {
    return undefined;
  }

  /**
   * Get icon and text to show on the add button when it is disabled
   * @returns {the icon class or nothing}
   */
  disabledAddButtonPlaceholder(resource?:HalResource):DisabledButtonPlaceholder|undefined {
    return undefined;
  }

  /**
   * Determines the specific warning to be shown, when there are no options to add as a list
   * @returns {the text or nothing}
   */
  warningTextWhenNoOptionsAvailable(hasMember?:boolean):Promise<string|undefined> {
    return Promise.resolve(undefined);
  }

  /**
   * Determine whether we can drag items into a given query for the
   * selected action value
   *
   * @param query
   * @param value
   */
  dragIntoAllowed(query:QueryResource, value:HalResource|undefined):boolean {
    return true;
  }

  /**
   * Determine whether we can create new items for this action attribute
   */
  canAddToQuery(query:QueryResource):Promise<boolean> {
    return Promise.resolve(true);
  }

  /**
   * Determine whether the given work package can be moved
   */
  canMove(workPackage:WorkPackageResource):boolean {
    const schema = this.schemaCache.of(workPackage);
    const fieldSchema = schema[this.filterName] as IFieldSchema;
    return fieldSchema?.writable;
  }

  /**
   * Assign the work package to the action attribute
   */
  assignToWorkPackage(changeset:WorkPackageChangeset, query:QueryResource) {
    // Ensure attribute remains writable in the form
    if (!changeset.isWritable(this.filterName)) {
      throw new Error(this.I18n.t(
        'js.boards.error_attribute_not_writable',
        { attribute: changeset.humanName(this.filterName) },
      ));
    }

    const except = ['project'];
    new WorkPackageFilterValues(this.injector, query.filters, except)
      .applyDefaultsFromFilters(changeset);
  }

  /**
   * Require the given resource to be loaded.
   *
   * @param id
   * @protected
   */
  protected abstract require(id:string):Promise<HalResource>;

  /**
   * Load values optionally matching the given name
   *
   * @param matching
   * @protected
   */
  protected abstract loadValues(matching?:string):Observable<HalResource[]>;
}
