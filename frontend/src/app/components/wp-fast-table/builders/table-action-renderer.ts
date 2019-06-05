import {Injector} from '@angular/core';
import {wpCellTdClassName} from './cell-builder';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {contextMenuSpanClassName, contextMenuTdClassName} from "core-components/wp-table/table-actions/table-action";

export class TableActionRenderer {

  // Injections
  readonly tableActionsService:OpTableActionsService = this.injector.get(OpTableActionsService);

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource):HTMLElement {
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
