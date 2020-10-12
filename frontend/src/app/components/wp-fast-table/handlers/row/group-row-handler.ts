import {Injector} from '@angular/core';
import {debugLog} from '../../../../helpers/debug_output';
import {GroupedRowsBuilder} from '../../builders/modes/grouped/grouped-rows-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventComponent, TableEventHandler} from '../table-handler-registry';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {rowGroupClassName} from "core-components/wp-fast-table/builders/modes/grouped/grouped-classes.constants";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class GroupRowHandler implements TableEventHandler {

  // Injections
  @InjectField() public querySpace:IsolatedQuerySpace;

  constructor(public readonly injector:Injector) {
  }

  public get EVENT() {
    return 'click.table.groupheader';
  }

  public get SELECTOR() {
    return `.${rowGroupClassName} .expander`;
  }

  public eventScope(view:TableEventComponent) {
    return jQuery(view.workPackageTable.tbody);
  }

  public handleEvent(view:TableEventComponent, evt:JQuery.TriggeredEvent) {
    evt.preventDefault();
    evt.stopPropagation();

    let groupHeader = jQuery(evt.target).parents(`.${rowGroupClassName}`);
    let groupIdentifier = groupHeader.data('groupIdentifier');
    let state = this.collapsedState.value || {};

    state[groupIdentifier] = !state[groupIdentifier];
    this.collapsedState.putValue(state);

    // Refresh groups
    const builder = new GroupedRowsBuilder(this.injector, view.workPackageTable);
    const t0 = performance.now();
    builder.refreshExpansionState();
    const t1 = performance.now();
    debugLog('Group redraw took ' + (t1 - t0) + ' milliseconds.');
  }

  private get collapsedState() {
    return this.querySpace.collapsedGroups;
  }
}
