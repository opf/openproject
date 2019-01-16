import {Injector} from '@angular/core';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {States} from 'core-components/states.service';
import {ApiV3Paths} from "core-app/modules/common/path-helper/apiv3/apiv3-paths";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";

export class DragAndDropTransformer {

  private readonly tableState:TableState = this.injector.get(TableState);
  private readonly states:States = this.injector.get(States);
  private readonly pathHelper = this.injector.get(PathHelperService);

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    const drake = dragula([this.table.tbody], {
      moves: function (el:any, source:any, handle:HTMLElement, sibling:any) {
        return handle.classList.contains('wp-table--drag-and-drop-handle');
      },
      accepts: () => true,
      invalid: () => false,
      direction: 'vertical',             // Y axis is considered when determining where an element would be dropped
      copy: false,                       // elements are moved by default, not copied
      revertOnSpill: true,               // spilling will put the element back where it was dragged from, if this is true
      removeOnSpill: false,              // spilling will `.remove` the element, if this is true
      mirrorContainer: document.body,    // set the element that gets mirror elements appended
      ignoreInputTextSelection: true     // allows users to select input text, see details below
    });

    drake.on('drop', (row:HTMLTableRowElement, target:any, source:HTMLTableRowElement, sibling:HTMLTableRowElement|null) => {
      this.tableState.rendered.doModify((rows) => {
        let fromIndex = rows.findIndex((el) => el.classIdentifier === row.dataset.classIdentifier);
        // New index can be taken from rowIndex - 1 (first row is thead>tr)
        let toIndex = row.rowIndex - 1;
        let target = rows.splice(fromIndex, 1)[0];
        rows.splice(toIndex, 0, target);
        return rows;
      });

      const query = this.tableState.query.value;
      if (query && !!query.updateImmediately) {
        const orderedWorkPackages = this.tableState.rendered.value!
          .filter((el) => !!el.workPackageId)
          .map(el => this.pathHelper.api.v3.work_packages.id(el.workPackageId!).toString());

          query.updateImmediately({ orderedWorkPackages: orderedWorkPackages} );
      }
    });

  }
}
