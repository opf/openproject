import {contextColumnIcon, OpTableAction} from 'core-components/wp-table/table-actions/table-action';
import {opIconElement} from 'core-app/helpers/op-icon-builder';

import {KeepTabService} from 'core-components/wp-single-view-tabs/keep-tab/keep-tab.service';
import {UiStateLinkBuilder} from 'core-components/wp-fast-table/builders/ui-state-link-builder';
import {StateService} from "@uirouter/core";

export const detailsLinkClassName = 'wp-table--details-link';

export class OpDetailsTableAction extends OpTableAction {

  public readonly identifier = 'open-details-action';
  private uiStatebuilder = new UiStateLinkBuilder(this.injector.get(StateService), this.injector.get(KeepTabService));
  private text = {
    button: this.I18n.t('js.button_open_details')
  }

  public buildElement() {
    // Append details button
    let detailsLink = this.uiStatebuilder.linkToDetails(
      this.workPackage.id!,
      this.text.button,
      ''
    );

    detailsLink.classList.add(detailsLinkClassName, contextColumnIcon, 'hidden-for-mobile');
    detailsLink.appendChild(opIconElement('icon', 'icon-info2'));

    return detailsLink;
  }
}
