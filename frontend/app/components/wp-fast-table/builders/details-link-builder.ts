import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {CellBuilder} from './cell-builder';
import {States} from '../../states.service';
import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
export const detailsLinkClassName = 'wp-table--details-link';

export class DetailsLinkBuilder {
  // Injections
  public I18n:op.I18n;

  constructor() {
    injectorBridge(this);
  }

  public build(workPackage:WorkPackageResource, row:HTMLElement) {
    // Append details button
    let td = document.createElement('td');
    td.classList.add('wp-table--details-column', 'hide-when-print', '-short');

    let detailsLink = document.createElement('a');
    detailsLink.classList.add(detailsLinkClassName, 'hidden-for-sighted');
    detailsLink.setAttribute('title', this.I18n.t('js.button_open_details'));
    detailsLink.dataset.workPackageId = workPackage.id;

    let icon = document.createElement('i');
    icon.classList.add('icon', 'icon-view-split');
    detailsLink.appendChild(icon);

    td.appendChild(detailsLink);
    row.appendChild(td);
  }
}


DetailsLinkBuilder.$inject = ['I18n'];
