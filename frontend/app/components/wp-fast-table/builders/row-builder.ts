import * as op from 'op';
import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageDisplayFieldService} from './../../wp-display/wp-display-field/wp-display-field.service';
import {CellBuilder} from './cell-builder';

export class RowBuilder {
  static PLACEHOLDER = '-';
  static CELLNAME = 'wp-table--edit-cell';

  private cellBuilder: CellBuilder;

  constructor(private wpDisplayField: WorkPackageDisplayFieldService,
              private I18n:op.I18n,
              private columns: any[]) {
    this.cellBuilder = new CellBuilder(wpDisplayField);
  }

  public buildEmpty(numCols:number) {
    let row = document.createElement('tr');
    let td = document.createElement('td');

    for (var i = numCols; i >= 0; i--) {
      row.appendChild(td);
    }

    return row;
  }

  public build(workPackage:WorkPackageResource, row:HTMLElement) {
    row.classList.add('wp--row', 'issue');

    this.columns.forEach((col:any) => {
      let cell = this.cellBuilder.build(workPackage, col.name);
      row.appendChild(cell);
    });

    // Last column
    let td = document.createElement('td');
    td.classList.add('wp-table--details-column', 'hide-when-print', '-short');

    let detailsLink = document.createElement('a');
    detailsLink.classList.add('wp-table--details-link', 'hidden-for-sighted');
    detailsLink.setAttribute('title', this.I18n.t('js.button_open_details'));

    let icon = document.createElement('i');
    icon.classList.add('icon', 'icon-view-split');
    detailsLink.appendChild(icon);

    td.appendChild(detailsLink);
    row.appendChild(td);
  }
}