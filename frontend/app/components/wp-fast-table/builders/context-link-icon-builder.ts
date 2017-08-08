import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {$injectFields, injectorBridge} from '../../angular/angular-injector-bridge.functions';
import {UiStateLinkBuilder} from './ui-state-link-builder';
import {opIconElement} from "../../../helpers/op-icon-builder";
import {wpCellTdClassName} from "./cell-builder";

export const contextMenuTdClassName = 'wp-table--context-menu-column';
export const contextMenuLinkClassName = 'wp-table-context-menu-link';

export class ContextLinkIconBuilder {
  // Injections
  public I18n: op.I18n;

  public text: any;

  constructor() {
    $injectFields(this, 'I18n');

    this.text = {
      button: this.I18n.t('js.button_open_details')
    };
  }

  public build(): HTMLElement {
    // Append details button
    let td = document.createElement('td');
    td.classList.add(wpCellTdClassName, contextMenuTdClassName, 'hide-when-print');

    // Enter the context menu arrow
    let detailsLink = document.createElement('a');
    detailsLink.classList.add(contextMenuLinkClassName, 'hidden-for-sighted');
    detailsLink.appendChild(opIconElement('icon', 'icon-pulldown'));
    td.appendChild(detailsLink);

    return td;
  }
}
