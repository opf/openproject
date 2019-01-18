import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {wpCellTdClassName} from "core-components/wp-fast-table/builders/cell-builder";
import {CdkDragPortalBody} from "core-components/wp-fast-table/builders/drag-and-drop/cdk-drag-portal-body";
import {PortalBuilder} from "core-components/wp-fast-table/builders/drag-and-drop/portal-builder";

export class CdkDragBuilder extends PortalBuilder<CdkDragPortalBody> {

  /**
   * Renders an angular CDK drag component into the column
   */
  public build(workPackage:WorkPackageResource):HTMLElement {
    // Append sort handle
    let td = document.createElement('td');
    td.classList.add(wpCellTdClassName, 'wp-table--sort-td', 'hide-when-print');

    this.attachWithPortal(td, CdkDragPortalBody);

    return td;
  }
}
