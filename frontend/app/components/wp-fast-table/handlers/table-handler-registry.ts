import {TimelineTransformer} from "./state/timeline-transformer";
import {HierarchyTransformer} from "./state/hierarchy-transformer";
import {WorkPackageTable} from "../wp-fast-table";
import {SelectionTransformer} from "./state/selection-transformer";
import {RowsTransformer} from "./state/rows-transformer";
import {ColumnsTransformer} from "./state/columns-transformer";
import {ContextMenuKeyboardHandler} from "./row/context-menu-keyboard-handler";
import {ContextMenuHandler} from "./row/context-menu-handler";
import {GroupRowHandler} from "./row/group-row-handler";
import {RowDoubleClickHandler} from "./row/double-click-handler";
import {RowClickHandler} from "./row/click-handler";
import {WorkPackageStateLinksHandler} from "./row/wp-state-links-handler";
import {EditCellHandler} from "./cell/edit-cell-handler";
import {HierarchyClickHandler} from "./row/hierarchy-click-handler";
import {RelationsCellHandler} from './cell/relations-cell-handler';
import {RelationsTransformer} from './state/relations-transformer';

export interface TableEventHandler {
  EVENT:string;
  SELECTOR:string;
  handleEvent(table:WorkPackageTable, evt:JQueryEventObject):void;
  eventScope(table:WorkPackageTable):JQuery;
}

export class TableHandlerRegistry {
  static eventHandlers: ((t: WorkPackageTable) => TableEventHandler)[] = [
    // Hierarchy expansion/collapsing
    t => new HierarchyClickHandler(t),
    // Clicking or pressing Enter on a single cell, editable or not
    t => new EditCellHandler(t),
    // Clicking on the details view
    t => new WorkPackageStateLinksHandler(t),
    // Clicking on the row (not within a cell)
    t => new RowClickHandler(t),
    t => new RowDoubleClickHandler(t),
    // Clicking on group headers
    t => new GroupRowHandler(t),
    // Right clicking on rows
    t => new ContextMenuHandler(t),
    // SHIFT+ALT+F10 on rows
    t => new ContextMenuKeyboardHandler(t),
    // Clicking on relations cells
    t => new RelationsCellHandler(t)
  ];

  static stateTransformers = [
    SelectionTransformer,
    RowsTransformer,
    ColumnsTransformer,
    TimelineTransformer,
    HierarchyTransformer,
    RelationsTransformer
  ];

  static attachTo(table: WorkPackageTable) {
    this.stateTransformers.map((cls) => {
      return new cls(table);
    });

    this.eventHandlers.map(factory => {
      let handler = factory(table);
      let target = handler.eventScope(table);

      target.on(handler.EVENT, handler.SELECTOR, (evt:JQueryEventObject) => {
        handler.handleEvent(table, evt);
      });

      return handler;
    });
  }

}
