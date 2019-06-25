import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {wpCellTdClassName} from "core-components/wp-fast-table/builders/cell-builder";
import {Injector} from "@angular/core";
import {TableDragActionsRegistryService} from "core-components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service";
import {TableDragActionService} from "core-components/wp-table/drag-and-drop/actions/table-drag-action.service";

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
  public build(workPackage:WorkPackageResource):HTMLElement {
    // Append sort handle
    let td = document.createElement('td');

    if (!this.actionService.canPickup(workPackage)) {
      return td;
    }

    td.classList.add(wpCellTdClassName, 'wp-table--sort-td', 'hide-when-print');

    // Wrap handle as span
    let span = document.createElement('span');
    span.classList.add('wp-table--drag-and-drop-handle', 'icon-toggle');
    td.appendChild(span);

    return td;
  }
}
