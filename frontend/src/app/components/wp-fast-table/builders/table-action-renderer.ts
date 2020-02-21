import {Injector} from '@angular/core';
import {tdClassName} from './cell-builder';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {contextMenuSpanClassName, contextMenuTdClassName} from "core-components/wp-table/table-actions/table-action";
import {internalContextMenuColumn} from "core-components/wp-fast-table/builders/internal-sort-columns";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class TableActionRenderer {

  // Injections
  @InjectField() tableActionsService:OpTableActionsService;

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource):HTMLElement {
    // Append details button
    let td = document.createElement('td');
    td.classList.add(tdClassName, contextMenuTdClassName, internalContextMenuColumn.id, 'hide-when-print');

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
