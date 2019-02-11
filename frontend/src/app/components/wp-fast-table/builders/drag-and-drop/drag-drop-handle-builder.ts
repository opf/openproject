import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {wpCellTdClassName} from "core-components/wp-fast-table/builders/cell-builder";

export class DragDropHandleBuilder {

  /**
   * Renders an angular CDK drag component into the column
   */
  public build(workPackage:WorkPackageResource):HTMLElement {
    // Append sort handle
    let td = document.createElement('td');
    td.classList.add(wpCellTdClassName, 'wp-table--sort-td', 'hide-when-print');

    // Wrap handle as span
    let span = document.createElement('span');
    span.classList.add('wp-table--drag-and-drop-handle', 'icon-toggle');
    td.appendChild(span);

    return td;
  }
}
