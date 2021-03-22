import { EventEmitter, Injector } from '@angular/core';
import { WorkPackageTable } from '../wp-fast-table';
import { EditCellHandler } from './cell/edit-cell-handler';
import { RelationsCellHandler } from './cell/relations-cell-handler';
import { ContextMenuClickHandler } from './context-menu/context-menu-click-handler';
import { ContextMenuKeyboardHandler } from './context-menu/context-menu-keyboard-handler';
import { ContextMenuRightClickHandler } from './context-menu/context-menu-rightclick-handler';
import { RowClickHandler } from './row/click-handler';
import { RowDoubleClickHandler } from './row/double-click-handler';
import { GroupRowHandler } from './row/group-row-handler';
import { HierarchyClickHandler } from './row/hierarchy-click-handler';
import { WorkPackageStateLinksHandler } from './row/wp-state-links-handler';
import { ColumnsTransformer } from './state/columns-transformer';
import { HierarchyTransformer } from './state/hierarchy-transformer';
import { RelationsTransformer } from './state/relations-transformer';
import { RowsTransformer } from './state/rows-transformer';
import { SelectionTransformer } from './state/selection-transformer';
import { TimelineTransformer } from './state/timeline-transformer';
import { HighlightingTransformer } from "core-components/wp-fast-table/handlers/state/highlighting-transformer";
import { DragAndDropTransformer } from "core-components/wp-fast-table/handlers/state/drag-and-drop-transformer";
import {
  WorkPackageViewEventHandler, WorkPackageViewOutputs,
  WorkPackageViewHandlerRegistry
} from "core-app/modules/work_packages/routing/wp-view-base/event-handling/event-handler-registry";
import { WorkPackageFocusContext } from "core-components/wp-table/wp-table.component";
import { GroupFoldTransformer } from "core-components/wp-fast-table/handlers/state/group-fold-transformer";

type StateTransformers = {
  // noinspection JSUnusedLocalSymbols
  new(injector:Injector, table:WorkPackageTable):any;
};

export interface TableEventComponent extends WorkPackageViewOutputs {
  // Reference to the fast table instance
  workPackageTable:WorkPackageTable;
}

export type TableEventHandler = WorkPackageViewEventHandler<TableEventComponent>;

export class TableHandlerRegistry extends WorkPackageViewHandlerRegistry<TableEventComponent> {

  protected eventHandlers:((t:TableEventComponent) => TableEventHandler)[] = [
    // Hierarchy expansion/collapsing
    () => new HierarchyClickHandler(this.injector),
    // Clicking or pressing Enter on a single cell, editable or not
    () => new EditCellHandler(this.injector),
    // Clicking on the details view
    () => new WorkPackageStateLinksHandler(this.injector),
    // Clicking on the row (not within a cell)
    () => new RowClickHandler(this.injector),
    // Double Clicking on the cell within the row
    () => new RowDoubleClickHandler(this.injector),
    // Clicking on group headers
    () => new GroupRowHandler(this.injector),
    // Right clicking on rows
    () => new ContextMenuRightClickHandler(this.injector),
    // Left clicking on the dropdown icon
    () => new ContextMenuClickHandler(this.injector),
    // SHIFT+ALT+F10 on rows
    () => new ContextMenuKeyboardHandler(this.injector),
    // Clicking on relations cells
    () => new RelationsCellHandler(this.injector)
  ];

  protected readonly stateTransformers:StateTransformers[] = [
    SelectionTransformer,
    RowsTransformer,
    ColumnsTransformer,
    GroupFoldTransformer,
    TimelineTransformer,
    HierarchyTransformer,
    RelationsTransformer,
    HighlightingTransformer,
    DragAndDropTransformer
  ];

  attachTo(viewRef:TableEventComponent) {
    this.stateTransformers.map((cls) => {
      return new cls(this.injector, viewRef.workPackageTable);
    });

    super.attachTo(viewRef);
  }
}
