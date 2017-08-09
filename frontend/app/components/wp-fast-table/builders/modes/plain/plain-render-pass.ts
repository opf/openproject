import {PrimaryRenderPass} from '../../primary-render-pass';
import {WorkPackageTable} from '../../../wp-fast-table';
import {SingleRowBuilder} from '../../rows/single-row-builder';

export class PlainRenderPass extends PrimaryRenderPass {

  constructor(public workPackageTable:WorkPackageTable,
              public rowBuilder:SingleRowBuilder) {
    super(workPackageTable, rowBuilder);
  }

  /**
   * The actual render function of this renderer.
   */
  protected doRender():void {
    this.workPackageTable.originalRows.forEach((wpId:string) => {
      let row = this.workPackageTable.originalRowIndex[wpId];
      let [tr,] = this.rowBuilder.buildEmpty(row.object);
      row.element = tr;
      this.appendRow(row.object, tr);
      this.tableBody.appendChild(tr);
    });
  }
}
