import {WorkPackageTable} from '../wp-fast-table';
import {RowClickHandler} from './row/click-handler';
import {EditCellHandler} from './cell/edit-cell-handler';
import {WorkPackageStateLinksHandler} from './row/wp-state-links-handler';
import {SelectionTransformer} from './state/selection-transformer';
import {RowsTransformer} from './state/rows-transformer';
import {ColumnsTransformer} from './state/columns-transformer';
import {GroupRowHandler} from './row/group-row-handler';
import {ContextMenuHandler} from './row/context-menu-handler';
import {ContextMenuKeyboardHandler} from './row/context-menu-keyboard-handler';

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
    RowClickHandler,
    // Clicking on group headers
    GroupRowHandler,
    // Right clicking on rows
    ContextMenuHandler,
    // SHIFT+ALT+F10 on rows
    ContextMenuKeyboardHandler,
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
