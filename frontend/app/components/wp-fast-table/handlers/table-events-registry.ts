import {WorkPackageTable} from '../wp-fast-table';
import {CellClickHandler} from './cell/click-handler';
import {RowClickHandler} from './row/click-handler';
import {MousetrapHandler} from './mousetrap-handler';
import {DetailsLinkClickHandler} from './row/details-link-click-handler';

export interface TableEventHandler {
  EVENT:string;
  SELECTOR:string;
  handleEvent(table: WorkPackageTable, evt: JQueryEventObject):void;
}

export class TableEventsRegistry {
  static eventHandlers = [
    // Clicking a single cell, editable or not
    CellClickHandler,
    // Clicking on the details view
    DetailsLinkClickHandler,
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
