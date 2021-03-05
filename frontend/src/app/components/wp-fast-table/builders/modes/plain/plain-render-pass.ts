import { Injector } from '@angular/core';
import { WorkPackageTable } from '../../../wp-fast-table';
import { PrimaryRenderPass } from '../../primary-render-pass';
import { SingleRowBuilder } from '../../rows/single-row-builder';

export class PlainRenderPass extends PrimaryRenderPass {

  constructor(public readonly injector:Injector,
              public workPackageTable:WorkPackageTable,
              public rowBuilder:SingleRowBuilder) {

    super(injector, workPackageTable, rowBuilder);
  }

  /**
   * The actual render function of this renderer.
   */
  protected doRender():void {
    this.workPackageTable.originalRows.forEach((wpId:string) => {
      const row = this.workPackageTable.originalRowIndex[wpId];
      const [tr,] = this.rowBuilder.buildEmpty(row.object);
      row.element = tr;
      this.appendRow(row.object, tr);
      this.tableBody.appendChild(tr);
    });
  }
}
