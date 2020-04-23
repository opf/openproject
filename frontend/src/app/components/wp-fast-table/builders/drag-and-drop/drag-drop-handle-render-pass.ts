import {Injector} from '@angular/core';
import {PrimaryRenderPass, RowRenderInfo} from '../primary-render-pass';
import {DragDropHandleBuilder} from "core-components/wp-fast-table/builders/drag-and-drop/drag-drop-handle-builder";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {WorkPackageViewOrderService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-order.service";
import {QueryOrder} from "core-app/modules/hal/dm-services/query-order-dm.service";
import {WorkPackageViewColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class DragDropHandleRenderPass {

  @InjectField() public wpTableColumns:WorkPackageViewColumnsService;
  @InjectField() public wpTableOrder:WorkPackageViewOrderService;

  // Drag & Drop handle builder
  protected dragDropHandleBuilder = new DragDropHandleBuilder(this.injector);

  constructor(public readonly injector:Injector,
              private table:WorkPackageTable,
              private tablePass:PrimaryRenderPass) {
  }

  public render() {
    if (!this.table.configuration.dragAndDropEnabled) {
      return;
    }


    this.wpTableOrder.withLoadedPositions().then((positions:QueryOrder) => {
      this.tablePass.renderedOrder.forEach((row:RowRenderInfo, position:number) => {
        // We only care for rows that are natural work packages and are not relation sub-rows
        if (!row.workPackage || row.renderType === 'relations') {
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
