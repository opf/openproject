import {Injector} from '@angular/core';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {PrimaryRenderPass, RowRenderInfo} from '../primary-render-pass';
import {DragDropHandleBuilder} from "core-components/wp-fast-table/builders/drag-and-drop/drag-drop-handle-builder";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";

export class DragDropHandleRenderPass {

  public wpTableColumns = this.injector.get(WorkPackageTableColumnsService);

  // Drag & Drop handle builder
  protected dragDropHandleBuilder = new DragDropHandleBuilder(this.injector);

  constructor(public readonly injector:Injector,
              private table:WorkPackageTable,
              private tablePass:PrimaryRenderPass) {
  }

  public render() {
    this.tablePass.renderedOrder.forEach((row:RowRenderInfo, position:number) => {
      // We only care for rows that are natural work packages and are not relation sub-rows
      if (!row.workPackage || row.renderType ===  'relations') {
        return;
      }

      const handle = this.dragDropHandleBuilder.build(row.workPackage!);

      if (handle) {
        row.element.replaceChild(handle, row.element.firstElementChild!);
      }
    });
  }
}
