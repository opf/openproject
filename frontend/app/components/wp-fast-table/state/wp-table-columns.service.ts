import {States} from '../../states.service';
import {opServicesModule} from '../../../angular-modules';
import {State} from '../../../helpers/reactive-fassade';
import {WPTableRowSelectionState} from '../wp-table.interfaces';

export class WorkPackageTableColumnsService {

  // Available columns state
  public availableColumnsState:State<any[]>;

  // The selected columns state of the current table instance
  public columnsState:State<string[]>;

  constructor(public states: States) {
    this.columnsState = states.table.columns;
    this.availableColumnsState = states.query.availableColumns;

    // Initialize as empty array for easier access
    if (!this.columnsState.hasValue()) {
      this.columnsState.put([]);
    }
  }

  /**
   * Retrieve the QueryColumn objects for the selected columns
   */
  public getColumns():any[] {
    let available = this.availableColumnsState.getCurrentValue();
    return this.currentState.map(name => {
      return _.find(available, (column) => column.name === name);
    });
  }

  /**
   * Return the index of the given column or -1 if it is not contained.
   */
  public index(name:string):number {
    return this.currentState.indexOf(name);
  }

  /**
   * Return the previous column of the given column name
   * @param name
   */
  public previous(name:string):string|null {
    let index = this.index(name);

    if (index <= 0) {
      return null;
    }

    return this.columnsState[index - 1];
  }

  /**
   * Return the next column of the given column name
   * @param name
   */
  public next(name:string):string|null {
    let index = this.index(name);

    if (index === -1 || this.isLast(name)) {
      return null;
    }

    return this.columnsState[index + 1];
  }

  /**
   * Returns true if the column is the first selected
   */
  public isFirst(name:string):boolean {
    return this.index(name) === 0;
  }

  /**
   * Returns true if the column is the last selected
   */
  public isLast(name:string):boolean {
    return this.index(name) === this.columnCount - 1;
  }

  /**
   * Move the column at index {fromIndex} to {toIndex}.
   * - If toIndex is larger than all columns, insert at the end.
   * - If toIndex is less than zero, insert at the start.
   */
  public moveColumn(fromIndex:number, toIndex:number) {
    let columns = this.currentState;

    if (toIndex >= columns.length) {
      toIndex = columns.length - 1;
    }

    if (toIndex < 0) {
      toIndex = 0;
    }

    let element = columns[fromIndex];
    columns.splice(fromIndex, 1);
    columns.splice(toIndex, 0, element);

    this.columnsState.put(columns);
  }

  /**
   * Shift the given column name X indices,
   * where X is the offset in indices (-1 = shift one to left)
   */
  public shift(name:string, offset:number) {
    let index = this.index(name);
    if (index === -1) {
      return;
    }

    this.moveColumn(index, index + offset);
  }

  /**
   * Add a new column to the selection at the given position
   */
  public addColumn(name:string, position:number) {
    let columns = this.currentState;
    columns.splice(position, 0, name);

    this.columnsState.put(columns);
  }

  /**
   * Remove a column from the active list
   */
  public removeColumn(name) {
    let index = this.index(name);

    if (index !== -1) {
      let columns = this.currentState.splice(index, 1);
      this.columnsState.put(columns);
    }
  }


  /**
   * Get current selection state.
   * @returns {WPTableRowSelectionState}
   */
  public get currentState():string[] {
    return this.columnsState.getCurrentValue();
  }

  /**
   * Return the number of selected rows.
   */
  public get columnCount():number {
    return this.currentState.length;
  }
}

opServicesModule.service('wpTableColumns', WorkPackageTableColumnsService);








