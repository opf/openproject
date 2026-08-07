//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import {
  HighlightingTransformer,
} from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/highlighting-transformer';
import {
  DragAndDropTransformer,
} from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/drag-and-drop-transformer';
import {
  WorkPackageViewEventHandler,
  WorkPackageViewHandlerRegistry,
  WorkPackageViewOutputs,
} from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';
import {
  GroupFoldTransformer,
} from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/group-fold-transformer';
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
import {
  SharingTransformer,
} from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/sharing-transformer';

// noinspection JSUnusedLocalSymbols
type StateTransformers = new(injector:Injector, table:WorkPackageTable) => any;

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
    () => new RelationsCellHandler(this.injector),
  ];

  protected readonly stateTransformers:StateTransformers[] = [
    SelectionTransformer,
    RowsTransformer,
    ColumnsTransformer,
    GroupFoldTransformer,
    TimelineTransformer,
    HierarchyTransformer,
    RelationsTransformer,
    SharingTransformer,
    HighlightingTransformer,
    DragAndDropTransformer,
  ];

  attachTo(viewRef:TableEventComponent) {
    this.stateTransformers.map((cls) => new cls(this.injector, viewRef.workPackageTable));

    super.attachTo(viewRef);
  }
}
