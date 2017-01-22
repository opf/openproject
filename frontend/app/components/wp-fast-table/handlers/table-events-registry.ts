import {WorkPackageTable} from '../wp-fast-table';
import {CellClickHandler} from './cell/click-handler';
import {RowClickHandler} from './row/click-handler';

export interface TableEventHandler {
  EVENT:string;
  SELECTOR:string;
  handleEvent(table: WorkPackageTable, evt: JQueryEventObject):void;
}

export class TableEventsRegistry {
  static handlers = [
    // Clicking a single cell, editable or not
    CellClickHandler,
    RowClickHandler
  ];

  static attachTo(table: WorkPackageTable) {
    let body = jQuery(table.tbody);

    this.handlers.forEach((cls) => {
      let handler = new cls();
      body.on(handler.EVENT, handler.SELECTOR, (evt:JQueryEventObject) => {
        handler.handleEvent(table, evt);
      });
    });
  }

}
