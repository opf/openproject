import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { tdClassName } from "core-components/wp-fast-table/builders/cell-builder";
import { Injector } from "@angular/core";
import { TableDragActionsRegistryService } from "core-components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service";
import { TableDragActionService } from "core-components/wp-table/drag-and-drop/actions/table-drag-action.service";
import { internalSortColumn } from "core-components/wp-fast-table/builders/internal-sort-columns";

/** Debug the render position */
const RENDER_DRAG_AND_DROP_POSITION = false;

export class DragDropHandleBuilder {

  // Injections
  private actionService:TableDragActionService;

  constructor(public readonly injector:Injector) {
    const dragActionRegistry = this.injector.get(TableDragActionsRegistryService);
    this.actionService = dragActionRegistry.get(injector);
  }

  /**
   * Renders an angular CDK drag component into the column
   */
  public build(workPackage:WorkPackageResource, position?:number):HTMLElement {
    // Append sort handle
    const td = document.createElement('td');

    td.classList.add(tdClassName, internalSortColumn.id);

    if (!this.actionService.canPickup(workPackage)) {
      return td;
    }

    td.classList.add('wp-table--sort-td', internalSortColumn.id,  'hide-when-print');

    // Wrap handle as span
    const span = document.createElement('span');
    span.classList.add('wp-table--drag-and-drop-handle', 'icon-drag-handle');
    td.appendChild(span);

    if (RENDER_DRAG_AND_DROP_POSITION) {
      const text = document.createElement('span');
      text.textContent = '' + position;
      td.appendChild(text);
    }

    return td;
  }
}
