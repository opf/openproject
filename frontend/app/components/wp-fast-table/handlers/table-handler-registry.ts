import {WorkPackageTable} from '../wp-fast-table';
import {RowClickHandler} from './row/click-handler';
import {EditCellHandler} from './cell/edit-cell-handler';
import {WorkPackageStateLinksHandler} from './row/wp-state-links-handler';
import {SelectionTransformer} from './state/selection-transformer';
import {RowsTransformer} from './state/rows-transformer';
import {ColumnsTransformer} from './state/columns-transformer';

export interface TableEventHandler {
  EVENT:string;
  SELECTOR:string;
  handleEvent(table: WorkPackageTable, evt: JQueryEventObject):void;
}

export class TableHandlerRegistry {
  static eventHandlers = [
    // Clicking or pressing Enter on a single cell, editable or not
    EditCellHandler,
    // Clicking on the details view
    WorkPackageStateLinksHandler,
    // Clicking on the row (not within a cell)
    RowClickHandler
  ];

  static stateTransformers = [
    SelectionTransformer,
    RowsTransformer,
    ColumnsTransformer,
  ];

  static attachTo(table: WorkPackageTable) {
    let body = jQuery(table.tbody);

    this.stateTransformers.map((cls) => {
      return new cls(table);
    });

    this.eventHandlers.map((cls) => {
      let handler = <TableEventHandler> new cls();
      body.on(handler.EVENT, handler.SELECTOR, (evt:JQueryEventObject) => {
        handler.handleEvent(table, evt);
      });

      return handler;
    });
  }

}
