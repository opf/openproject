import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {rowClassName} from '../../builders/single-row-builder';
import {tdClassName} from '../../builders/cell-builder';
import {GroupedRowsBuilder, rowGroupClassName} from '../../builders/grouped-rows-builder';

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

    console.log('GROUP HEADER CLICK!');
    let groupHeader = jQuery(evt.target).parents(`.${rowGroupClassName}`);
    let groupIndex = groupHeader.data('groupIndex');
    let state = this.collapsedState.getCurrentValue() || {};

    state[groupIndex] = !state[groupIndex];
    this.collapsedState.put(state);

    // Refresh groups
    var t0 = performance.now();

    this.builder.refreshExpansionState(table);

    var t1 = performance.now();
    console.log("Group redraw took " + (t1 - t0) + " milliseconds.");
  }

  private get collapsedState() {
    return this.states.table.collapsedGroups;
  }
}

GroupRowHandler.$inject = ['states'];
