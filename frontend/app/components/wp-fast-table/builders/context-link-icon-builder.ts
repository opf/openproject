import {Injector} from '@angular/core';
import {$stateToken, I18nToken} from 'core-app/angular4-transition-utils';
import {KeepTabService} from 'core-components/wp-panels/keep-tab/keep-tab.service';
import {opIconElement} from '../../../helpers/op-icon-builder';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {wpCellTdClassName} from './cell-builder';
import {UiStateLinkBuilder} from './ui-state-link-builder';

export const contextMenuTdClassName = 'wp-table--context-menu-td';
export const contextMenuSpanClassName = 'wp-table--context-menu-span';
export const contextMenuLinkClassName = 'wp-table-context-menu-link';
export const contextColumnIcon = 'wp-table-context-menu-icon';
export const detailsLinkClassName = 'wp-table--details-link';

export class ContextLinkIconBuilder {

  // Injections
  public I18n:op.I18n = this.injector.get(I18nToken);

  public text:any;
  public uiStatebuilder = new UiStateLinkBuilder(this.injector.get($stateToken), this.injector.get(KeepTabService));

  constructor(public readonly injector:Injector) {
    this.text = {
      button: this.I18n.t('js.button_open_details')
    };
  }

  public build(workPackage:WorkPackageResourceInterface):HTMLElement {
    // Append details button
    let td = document.createElement('td');
    td.classList.add(wpCellTdClassName, contextMenuTdClassName, 'hide-when-print');

    let detailsLink = this.uiStatebuilder.linkToDetails(
      workPackage.id,
      this.text.button,
      ''
    );

    detailsLink.classList.add(detailsLinkClassName, contextColumnIcon, 'hidden-for-mobile');
    detailsLink.appendChild(opIconElement('icon', 'icon-info2'));

    // Enter the context menu arrow
    let contextMenu = document.createElement('a');
    contextMenu.href = 'javascript:';
    contextMenu.classList.add(contextMenuLinkClassName, contextColumnIcon);
    contextMenu.appendChild(opIconElement('icon', 'icon-show-more-horizontal'));

    // Wrap both icons in a span
    let span = document.createElement('span');
    span.classList.add(contextMenuSpanClassName);
    span.appendChild(detailsLink);
    span.appendChild(contextMenu);

    td.appendChild(span);
    return td;
  }
}
