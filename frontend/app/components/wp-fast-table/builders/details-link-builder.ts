import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
import {UiStateLinkBuilder} from './ui-state-link-builder';
export const detailsLinkClassName = 'wp-table--details-link';

export class DetailsLinkBuilder {
  // Injections
  public I18n:op.I18n;

  public text:any;

  constructor() {
    injectorBridge(this);
    this.text = {
      button: this.I18n.t('js.button_open_details')
    };
  }

  public build(workPackage:WorkPackageResource, row:HTMLElement) {
    // Append details button
    let td = document.createElement('td');
    td.classList.add('wp-table--details-column', 'hide-when-print', '-short');

    let detailsLink = UiStateLinkBuilder.linkToDetails(
      <number> workPackage.id,
      this.text.button,
      ''
    );

    detailsLink.classList.add(detailsLinkClassName, 'hidden-for-sighted');
    let icon = document.createElement('i');
    icon.classList.add('icon', 'icon-view-split');
    detailsLink.appendChild(icon);

    td.appendChild(detailsLink);
    row.appendChild(td);
  }
}


DetailsLinkBuilder.$inject = ['I18n'];
