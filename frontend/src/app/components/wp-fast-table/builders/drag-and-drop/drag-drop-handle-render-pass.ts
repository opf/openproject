import {Injector} from '@angular/core';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {PrimaryRenderPass, RowRenderInfo} from '../primary-render-pass';
import {DragDropHandleBuilder} from "core-components/wp-fast-table/builders/drag-and-drop/drag-drop-handle-builder";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {WorkPackageTableOrderService} from "core-components/wp-fast-table/state/wp-table-order.service";
import {QueryOrder} from "core-app/modules/hal/dm-services/query-order-dm.service";

export class DragDropHandleRenderPass {

  public wpTableColumns = this.injector.get(WorkPackageTableColumnsService);
  public wpTableOrder = this.injector.get(WorkPackageTableOrderService);

  // Drag & Drop handle builder
  protected dragDropHandleBuilder = new DragDropHandleBuilder(this.injector);

  constructor(public readonly injector:Injector,
              private table:WorkPackageTable,
              private tablePass:PrimaryRenderPass) {
  }

  public render() {
    this.wpTableOrder.withLoadedPositions().then((positions:QueryOrder) => {
      this.tablePass.renderedOrder.forEach((row:RowRenderInfo, position:number) => {
        // We only care for rows that are natural work packages and are not relation sub-rows
        if (!row.workPackage || row.renderType ===  'relations') {
          return;
        }

        const handle = this.dragDropHandleBuilder.build(row.workPackage!, positions[row.workPackage!.id!]);

        if (handle) {
          row.element.replaceChild(handle, row.element.firstElementChild!);
        }
      });
    });
  }
}
