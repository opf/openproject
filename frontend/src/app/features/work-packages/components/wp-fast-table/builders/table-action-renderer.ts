//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { OpTableActionsService } from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { contextMenuSpanClassName, contextMenuTdClassName } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { internalContextMenuColumn } from 'core-app/features/work-packages/components/wp-fast-table/builders/internal-sort-columns';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { tdClassName } from './cell-builder';

export class TableActionRenderer {
  // Injections
  @LazyInject() tableActionsService:OpTableActionsService;

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource):HTMLTableCellElement{
    // Append details button
    const td = document.createElement('td');
    td.classList.add(tdClassName, contextMenuTdClassName, internalContextMenuColumn.id, 'hide-when-print');

    // Wrap any actions in a span
    const span = document.createElement('span');
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
