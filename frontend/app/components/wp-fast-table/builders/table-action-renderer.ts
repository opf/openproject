import {Injector} from '@angular/core';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {wpCellTdClassName} from './cell-builder';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';

export const contextMenuTdClassName = 'wp-table--context-menu-td';
export const contextMenuSpanClassName = 'wp-table--context-menu-span';
export const contextMenuLinkClassName = 'wp-table-context-menu-link';
export const contextColumnIcon = 'wp-table-context-menu-icon';


export class TableActionRenderer {

  // Injections
  readonly tableActionsService:OpTableActionsService = this.injector.get(OpTableActionsService);

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResourceInterface):HTMLElement {
    // Append details button
    let td = document.createElement('td');
    td.classList.add(wpCellTdClassName, contextMenuTdClassName, 'hide-when-print');

    // Wrap any actions in a span
    let span = document.createElement('span');
    span.classList.add(contextMenuSpanClassName);

    this.tableActionsService
      .render(workPackage)
      .forEach((el:HTMLElement) => {
        span.appendChild(el);
    });

    td.appendChild(span);
    return td;
  }
}
