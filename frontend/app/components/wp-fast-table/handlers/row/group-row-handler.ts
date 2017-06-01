import {debugLog} from "../../../../helpers/debug_output";
import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageTable} from "../../wp-fast-table";
import {States} from "../../../states.service";
import {TableEventHandler} from "../table-handler-registry";
import {
  GroupedRowsBuilder,
  rowGroupClassName
} from "../../builders/modes/grouped/grouped-rows-builder";

export class GroupRowHandler implements TableEventHandler {
  // Injections
  public states:States;

  private builder:GroupedRowsBuilder;

  constructor(table: WorkPackageTable) {
    injectorBridge(this);
    this.builder = new GroupedRowsBuilder(table);
  }

  public get EVENT() {
    return 'click.table.groupheader';
  }

  public get SELECTOR() {
    return `.${rowGroupClassName} .expander`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.tbody);
  }

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    evt.preventDefault();
    evt.stopPropagation();

    let groupHeader = jQuery(evt.target).parents(`.${rowGroupClassName}`);
    let groupIdentifier = groupHeader.data('groupIdentifier');
    let state = this.collapsedState.value || {};

    state[groupIdentifier] = !state[groupIdentifier];
    this.collapsedState.putValue(state);

    // Refresh groups
    var t0 = performance.now();
    this.builder.refreshExpansionState();
    var t1 = performance.now();
    debugLog("Group redraw took " + (t1 - t0) + " milliseconds.");
  }

  private get collapsedState() {
    return this.states.table.collapsedGroups;
  }
}

GroupRowHandler.$inject = ['states'];
