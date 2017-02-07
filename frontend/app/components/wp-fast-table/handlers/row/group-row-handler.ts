import {debug_log} from '../../../../helpers/debug_output';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {rowClassName} from '../../builders/rows/single-row-builder';
import {tdClassName} from '../../builders/cell-builder';
import {GroupedRowsBuilder, rowGroupClassName} from '../../builders/rows/grouped-rows-builder';

export class GroupRowHandler implements TableEventHandler {
  // Injections
  public states:States;

  private builder:GroupedRowsBuilder;

  constructor() {
    injectorBridge(this);
    this.builder = new GroupedRowsBuilder();
  }

  public get EVENT() {
    return 'click.table.groupheader';
  }

  public get SELECTOR() {
    return `.${rowGroupClassName} .expander`;
  }

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    evt.preventDefault();
    evt.stopPropagation();

    let groupHeader = jQuery(evt.target).parents(`.${rowGroupClassName}`);
    let groupIdentifier = groupHeader.data('groupIdentifier');
    let state = this.collapsedState.getCurrentValue() || {};

    state[groupIdentifier] = !state[groupIdentifier];
    this.collapsedState.put(state);

    // Refresh groups
    setTimeout(() => {
      var t0 = performance.now();
      this.builder.refreshExpansionState(table);
      var t1 = performance.now();
      debug_log("Group redraw took " + (t1 - t0) + " milliseconds.");
    });
  }

  private get collapsedState() {
    return this.states.table.collapsedGroups;
  }
}

GroupRowHandler.$inject = ['states'];
