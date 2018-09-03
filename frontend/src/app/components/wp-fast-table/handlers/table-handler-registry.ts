import {Injector} from '@angular/core';
import {WorkPackageTable} from '../wp-fast-table';
import {EditCellHandler} from './cell/edit-cell-handler';
import {RelationsCellHandler} from './cell/relations-cell-handler';
import {ContextMenuClickHandler} from './context-menu/context-menu-click-handler';
import {ContextMenuKeyboardHandler} from './context-menu/context-menu-keyboard-handler';
import {ContextMenuRightClickHandler} from './context-menu/context-menu-rightclick-handler';
import {RowClickHandler} from './row/click-handler';
import {RowDoubleClickHandler} from './row/double-click-handler';
import {GroupRowHandler} from './row/group-row-handler';
import {HierarchyClickHandler} from './row/hierarchy-click-handler';
import {WorkPackageStateLinksHandler} from './row/wp-state-links-handler';
import {ColumnsTransformer} from './state/columns-transformer';
import {HierarchyTransformer} from './state/hierarchy-transformer';
import {RelationsTransformer} from './state/relations-transformer';
import {RowsTransformer} from './state/rows-transformer';
import {SelectionTransformer} from './state/selection-transformer';
import {TimelineTransformer} from './state/timeline-transformer';
import {HighlightingTransformer} from "core-components/wp-fast-table/handlers/state/highlighting-transformer";

export interface TableEventHandler {
  EVENT:string;
  SELECTOR:string;

  handleEvent(table:WorkPackageTable, evt:JQueryEventObject):void;

  eventScope(table:WorkPackageTable):JQuery;
}

type StateTransformers = {
  // noinspection JSUnusedLocalSymbols
  new(injector:Injector, table:WorkPackageTable):any;
};

export class TableHandlerRegistry {

  constructor(public readonly injector:Injector) {
  }

  private eventHandlers:((t:WorkPackageTable) => TableEventHandler)[] = [
    // Hierarchy expansion/collapsing
    t => new HierarchyClickHandler(this.injector, t),
    // Clicking or pressing Enter on a single cell, editable or not
    t => new EditCellHandler(this.injector, t),
    // Clicking on the details view
    t => new WorkPackageStateLinksHandler(this.injector, t),
    // Clicking on the row (not within a cell)
    t => new RowClickHandler(this.injector, t),
    // Double Clicking on the row (not within a cell)
    t => new RowDoubleClickHandler(this.injector, t),
    // Clicking on group headers
    t => new GroupRowHandler(this.injector, t),
    // Right clicking on rows
    t => new ContextMenuRightClickHandler(this.injector, t),
    // Left clicking on the dropdown icon
    t => new ContextMenuClickHandler(this.injector, t),
    // SHIFT+ALT+F10 on rows
    t => new ContextMenuKeyboardHandler(this.injector, t),
    // Clicking on relations cells
    t => new RelationsCellHandler(this.injector, t)
  ];

  private readonly stateTransformers:StateTransformers[] = [
    SelectionTransformer,
    RowsTransformer,
    ColumnsTransformer,
    TimelineTransformer,
    HierarchyTransformer,
    RelationsTransformer,
    HighlightingTransformer
  ];

  attachTo(table:WorkPackageTable) {
    this.stateTransformers.map((cls) => {
      return new cls(this.injector, table);
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
