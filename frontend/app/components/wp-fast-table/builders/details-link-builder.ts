import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
import {UiStateLinkBuilder} from './ui-state-link-builder';
import {opIconElement} from "../../../helpers/op-icon-builder";

export const detailsLinkTdClass = 'wp-table--details-column';
export const detailsLinkClassName = 'wp-table--details-link';

export class DetailsLinkBuilder {
  // Injections
  public I18n: op.I18n;

  public text: any;
  private uiStatebuilder: UiStateLinkBuilder;

  constructor() {
    injectorBridge(this);
    this.text = {
      button: this.I18n.t('js.button_open_details')
    };
    this.uiStatebuilder = new UiStateLinkBuilder();
  }

  public build(workPackage: WorkPackageResource): HTMLElement {
    // Append details button
    let td = document.createElement('td');
    td.classList.add(detailsLinkTdClass, 'hide-when-print');

    let detailsLink = this.uiStatebuilder.linkToDetails(
      workPackage.id,
      this.text.button,
      ''
    );

    detailsLink.classList.add(detailsLinkClassName, 'hidden-for-sighted');
    detailsLink.appendChild(opIconElement('icon', 'icon-info2'));
    td.appendChild(detailsLink);

    return td;
  }
}

DetailsLinkBuilder.$inject = ['I18n'];
