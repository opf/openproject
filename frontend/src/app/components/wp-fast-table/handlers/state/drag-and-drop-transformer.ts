import {Injector} from '@angular/core';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {States} from 'core-components/states.service';

export class DragAndDropTransformer {

  public tableState:TableState = this.injector.get(TableState);
  public states:States = this.injector.get(States);

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    dragula([this.table.tbody], {
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

  }
}
