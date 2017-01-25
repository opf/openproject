import {WorkPackageTable} from '../wp-fast-table';
import {RowClickHandler} from './row/click-handler';
import {MousetrapHandler} from './global-mousetrap-handler';
import {EditCellHandler} from './cell/edit-cell-handler';
import {WorkPackageStateLinksHandler} from './row/wp-state-links-handler';

export interface TableEventHandler {
  EVENT:string;
  SELECTOR:string;
  handleEvent(table: WorkPackageTable, evt: JQueryEventObject):void;
}

export class TableEventsRegistry {
  static eventHandlers = [
    // Clicking or pressing Enter on a single cell, editable or not
    EditCellHandler,
    // Clicking on the details view
    WorkPackageStateLinksHandler,
    // Clicking on the row (not within a cell)
    RowClickHandler
  ];

  static delegatedHandlers = [
    MousetrapHandler
  ];

  static attachTo(table: WorkPackageTable) {
    let body = jQuery(table.tbody);

    this.delegatedHandlers.map((cls) => {
      let handler = new cls();
      handler.attachTo(table);
    });

    this.eventHandlers.map((cls) => {
      let handler = new cls();
      body.on(handler.EVENT, handler.SELECTOR, (evt:JQueryEventObject) => {
        handler.handleEvent(table, evt);
      });
    });
  }

}
