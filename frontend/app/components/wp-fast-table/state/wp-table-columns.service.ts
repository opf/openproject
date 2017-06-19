// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {
  TableStateStates,
  WorkPackageQueryStateService,
  WorkPackageTableBaseService
} from './wp-table-base.service';
import {States} from '../../states.service';
import {opServicesModule} from '../../../angular-modules';
import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service';
import {WorkPackageTableColumns} from '../wp-table-columns';
import {QuerySchemaResourceInterface} from '../../api/api-v3/hal-resources/query-schema-resource.service';
import {QueryColumn, queryColumnTypes} from '../../wp-query/query-column';

export class WorkPackageTableColumnsService extends WorkPackageTableBaseService implements WorkPackageQueryStateService {
  protected stateName = 'columns' as TableStateStates;

  constructor(protected states: States) {
    super(states);
  }

  public initialize(query:QueryResource, schema?:QuerySchemaResourceInterface) {
    let state = new WorkPackageTableColumns(query);
    this.state.putValue(state);
  }

  public update(query:QueryResource, schema?:QuerySchemaResourceInterface) {
    let currentState = this.currentState;

    if (currentState) {
      currentState.update(query, schema);
      this.state.putValue(currentState);
    } else {
      this.initialize(query, schema);
    }
  }

  public hasChanged(query:QueryResource) {
    const comparer = (columns:QueryColumn[]) => columns.map(c => c.href);

    return !_.isEqual(
      comparer(query.columns),
      comparer(this.getColumns())
    );
  }

  public applyToQuery(query:QueryResource) {
    query.columns = _.cloneDeep(this.getColumns());

    // Reload the table visibly if adding relation columns.
    return this.hasRelationColumns();
  }

  /**
   * Returns whether the current set of columns include relations
   */
  public hasRelationColumns() {
    const relationColumns = [queryColumnTypes.RELATION_OF_TYPE, queryColumnTypes.RELATION_TO_TYPE];
    return !!_.find(this.getColumns(), (c) => relationColumns.indexOf(c._type) >= 0);
  }

  /**
   * Retrieve the QueryColumn objects for the selected columns
   */
  public getColumns():any[] {
    return (this.currentState && this.currentState.getColumns()) || [];
  }

  /**
   * Return the index of the given column or -1 if it is not contained.
   */
  public index(id:string):number {
    return _.findIndex(this.getColumns(), column => column.id === id);
  }

  /**
   * Return the column object for the given id.
   * @param id
   */
  public findById(id:string):QueryColumn|undefined {
    return _.find(this.getColumns(), column => column.id === id);
  }

  /**
   * Return the previous column of the given column name
   * @param name
   */
  public previous(column:QueryColumn):QueryColumn|null {
    let index = this.index(column.id);

    if (index <= 0) {
      return null;
    }

    return this.getColumns()[index - 1];
  }

  /**
   * Return the next column of the given column name
   * @param name
   */
  public next(column:QueryColumn):QueryColumn|null {
    let index = this.index(column.id);

    if (index === -1 || this.isLast(name)) {
      return null;
    }

    return this.getColumns()[index + 1];
  }

  /**
   * Returns true if the column is the first selected
   */
  public isFirst(column:QueryColumn):boolean {
    return this.index(column.id) === 0;
  }

  /**
   * Returns true if the column is the last selected
   */
  public isLast(column:QueryColumn):boolean {
    return this.index(column.id) === this.columnCount - 1;
  }

  /**
   * Update the selected columns to a new set of columns.
   */
  public setColumns(columns:QueryColumn[]) {
    let currentState = this.currentState;

    currentState.current = columns;

    this.state.putValue(currentState);
  }

  /**
   * Move the column at index {fromIndex} to {toIndex}.
   * - If toIndex is larger than all columns, insert at the end.
   * - If toIndex is less than zero, insert at the start.
   */
  public moveColumn(fromIndex:number, toIndex:number) {
    let columns = this.getColumns();

    if (toIndex >= columns.length) {
      toIndex = columns.length - 1;
    }

    if (toIndex < 0) {
      toIndex = 0;
    }

    let element = columns[fromIndex];
    columns.splice(fromIndex, 1);
    columns.splice(toIndex, 0, element);

    this.setColumns(columns);
  }

  /**
   * Shift the given column name X indices,
   * where X is the offset in indices (-1 = shift one to left)
   */
  public shift(column:QueryColumn, offset:number) {
    let index = this.index(column.id);
    if (index === -1) {
      return;
    }

    this.moveColumn(index, index + offset);
  }

  /**
   * Add a new column to the selection at the given position
   */
  public addColumn(id:string, position?:number) {
    let columns = this.getColumns();

    if (position === undefined) {
      position = columns.length;
    }

    if (this.index(id) === -1) {
      let newColumn =  _.find(this.all, (column) => column.id === id);

      if (!newColumn) {
        throw "Column with provided name is not found";
      }

      columns.splice(position, 0, newColumn);
      this.setColumns(columns);
    }
  }

  /**
   * Remove a column from the active list
   */
  public removeColumn(column:QueryColumn) {
    let index = this.index(column.id);

    if (index !== -1) {
      let columns = this.getColumns();
      columns.splice(index, 1);
      this.setColumns(columns);
    }
  }

  // only exists to cast the state
  protected get currentState():WorkPackageTableColumns {
    return this.state.value as WorkPackageTableColumns;
  }

  // Get the available state
  protected get availableState() {
    return this.states.query.available.columns;
  }

  /**
   * Return the number of selected rows.
   */
  public get columnCount():number {
    return this.getColumns().length;
  }

  /**
   * Get all available columns (regardless of whether they are selected already)
   */
  public get all():QueryColumn[] {
    return this.availableState.getValueOr([]);
  }

  /**
   * Get columns not yet selected
   */
  public get unused():QueryColumn[] {
    return _.differenceBy(this.all, this.getColumns(), '$href');
  }
}

opServicesModule.service('wpTableColumns', WorkPackageTableColumnsService);
