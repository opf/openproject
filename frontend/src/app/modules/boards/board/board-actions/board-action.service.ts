import {Board} from "core-app/modules/boards/board/board";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {ComponentType} from "@angular/cdk/portal";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";
import {DisabledButtonPlaceholder} from "core-app/modules/boards/board/board-list/board-list.component";

export interface BoardActionService {

  /**
   * Get the attribute name
   */
  localizedName:string;

  /**
   * Returns the current filter value ID if any
   * @param query
   * @returns /api/v3/status/:id if a status filter exists
   */
  getFilterHref(query:QueryResource):string|undefined;

  /**
   * Returns the current filter value if any
   * @param query
   * @returns /api/v3/status/:id if a status filter exists
   */
  getLoadedFilterValue(query:QueryResource):Promise<HalResource|undefined>;

  /**
   * Add initial queries to a new board
   *
   * @param newBoard
   */
  addActionQueries(newBoard:Board):Promise<Board>;

  /**
   * Add a single action query
   */
  addActionQuery(board:Board, value:HalResource):Promise<Board>;

  /**
   * Get available values from the active queries
   *
   * @param board The board we're looking at
   * @param active The active set of values (hrefs or plain values)
   */
  getAvailableValues(board:Board, active:Set<string>):Promise<HalResource[]>;

  /**
   * Get action specific items that shall be shown in the list menu
   * @returns {any[]}
   */
  getAdditionalListMenuItems(query:QueryResource):Promise<OpContextMenuItem[]>;

  /**
   * Determine whether we can drag items into a given query for the
   * selected action value
   *
   * @param query
   * @param value
   */
  dragIntoAllowed(query:QueryResource, value:HalResource|undefined):boolean;

  /**
   * Determine whether we can create new items for this action attribute
   */
  canAddToQuery(query:QueryResource):Promise<boolean>;


  /**
   * Get the specific component for the autocompleter (e.g versionAutocompleter)
   * @returns {Component}
   */
  autocompleterComponent():ComponentType<unknown>;

  /**
   * Get the specific header component for the board list, or undefined if none
   * @returns {Component}
   */
  headerComponent():ComponentType<unknown>|undefined;

  /**
   * Get icon and text to show on the add button when it is disabled
   * @returns {the icon class or nothing}
   */
  disabledAddButtonPlaceholder(resource?:HalResource):DisabledButtonPlaceholder|undefined;

  /**
   * Determines the specific warning to be shown, when there are no options to add as a list
   * @returns {the text or nothing}
   */
  warningTextWhenNoOptionsAvailable():Promise<string|undefined>;
}
