import {States} from '../../states.service';
import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
import {WorkPackageTableColumnsService} from '../state/wp-table-columns.service';
import {State} from '../../../helpers/reactive-fassade';
import {WorkPackageTable} from '../wp-fast-table';
import {SingleRowBuilder} from './single-row-builder';
import {RowsBuilderInterface} from '../wp-table.interfaces';

export class PlainRowsBuilder implements RowsBuilderInterface {
  // Injections
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;
  public I18n:op.I18n;

  private rowBuilder = new SingleRowBuilder();

  // The group expansion state
  constructor() {
    injectorBridge(this);
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   * @param table
   */
  public buildRows(table:WorkPackageTable):DocumentFragment {
    let tbodyContent = document.createDocumentFragment();

    table.rows.forEach((wpId:string) => {
      let row = table.rowIndex[wpId];
      let tr = this.redrawRow(row);
      row.element = tr;
      tbodyContent.appendChild(tr);
    });

    return tbodyContent;
  }

  public redrawRow(row, table?:WorkPackageTable) {
    return this.rowBuilder.buildEmpty(row.object);
  }
}


PlainRowsBuilder.$inject = ['wpTableColumns', 'states', 'I18n'];
