import {RowsBuilder} from './rows-builder';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';

export class EmptyRowsBuilder extends RowsBuilder {
  // Injections
  public I18n:op.I18n;
  public wpTableColumns:WorkPackageTableColumnsService;

  private text;

  constructor() {
    super();
    injectorBridge(this);

    this.text = {
      noResults: {
        title: _.escape(this.I18n.t('js.work_packages.no_results.title')),
        description: _.escape(this.I18n.t('js.work_packages.no_results.description'))
      },
    }
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   * @param table
   */
  public buildRows(table:WorkPackageTable):DocumentFragment {
    let colspan = this.wpTableColumns.columnCount + 1;
    let tbodyContent = document.createDocumentFragment();
    let tr = document.createElement('tr');

    tr.id = 'empty-row-notification';
    tr.innerHTML = `
      <td colspan="${colspan}">
        <span>
          <i class="icon-context icon-info1"></i>
          <strong>${this.text.noResults.title}</strong>
          <span>${this.text.noResults.description}</span>
        </span>
      </td>
    `;


    tbodyContent.appendChild(tr);
    return tbodyContent;
  }

  public buildEmptyRow() {
    return document.createElement('tr');
  }
}


EmptyRowsBuilder.$inject = ['wpTableColumns', 'I18n'];

