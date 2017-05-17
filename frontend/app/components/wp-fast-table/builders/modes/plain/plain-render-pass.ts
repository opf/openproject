import {TableRenderPass} from '../table-render-pass';
import {WorkPackageTable} from '../../../wp-fast-table';
import {SingleRowBuilder} from '../../rows/single-row-builder';
import {Subject} from 'rxjs';

export class PlainRenderPass extends TableRenderPass {

  constructor(public workPackageTable:WorkPackageTable,
              public stopExisting$:Subject<undefined>,
              public rowBuilder:SingleRowBuilder) {
    super(stopExisting$, workPackageTable);
  }

  /**
   * The actual render function of this renderer.
   */
  protected doRender():void {
    this.workPackageTable.rows.forEach((wpId:string) => {
      let row = this.workPackageTable.rowIndex[wpId];
      let [tr, _hidden] = this.rowBuilder.buildEmpty(row.object);
      row.element = tr;
      this.appendRow(row.object, tr);
      this.tableBody.appendChild(tr);
    });
  }
}
