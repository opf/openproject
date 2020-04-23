import {Injector} from '@angular/core';
import {debugLog} from '../../../../helpers/debug_output';
import {GroupedRowsBuilder} from '../../builders/modes/grouped/grouped-rows-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventHandler} from '../table-handler-registry';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {rowGroupClassName} from "core-components/wp-fast-table/builders/modes/grouped/grouped-classes.constants";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class GroupRowHandler implements TableEventHandler {

  // Injections
  @InjectField() public querySpace:IsolatedQuerySpace;

  private builder:GroupedRowsBuilder;

  constructor(public readonly injector:Injector, table:WorkPackageTable) {
    this.builder = new GroupedRowsBuilder(injector, table);
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

  public handleEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent) {
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
    debugLog('Group redraw took ' + (t1 - t0) + ' milliseconds.');
  }

  private get collapsedState() {
    return this.querySpace.collapsedGroups;
  }
}
