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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Directive, effect, ElementRef, inject, input, untracked } from '@angular/core';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { TemplateWorkPackageRow, TemplateRowView } from './template-row';

/**
 * Hosts the cell markup of today's cell builders in a template cell, so
 * display fields can move to templates one field type at a time.
 */
@Directive({ selector: 'td[opWpTableCell], th[opWpTableCell]' })
export class WorkPackageTableCellDirective {
  readonly column = input.required<QueryColumn>();
  readonly row = input.required<TemplateWorkPackageRow>();
  readonly view = input.required<TemplateRowView>();

  private readonly cell = inject<ElementRef<HTMLTableCellElement>>(ElementRef).nativeElement;

  constructor() {
    effect(() => {
      const column = this.column();
      const row = this.row();
      const view = this.view();

      untracked(() => {
        if (view.isEditing(row.workPackage, column, this.cell)) return;

        const built = view.buildCell(row, column);
        if (built) this.adopt(built);
      });
    });
  }

  private adopt(built:HTMLTableCellElement):void {
    Array.from(this.cell.attributes)
      .filter((attribute) => !built.hasAttribute(attribute.name))
      .forEach((attribute) => this.cell.removeAttribute(attribute.name));
    Array.from(built.attributes).forEach((attribute) => this.cell.setAttribute(attribute.name, attribute.value));
    this.cell.replaceChildren(...Array.from(built.childNodes));
  }
}

@Directive({ selector: '[opWpTableCellContent]' })
export class WorkPackageTableCellContentDirective {
  readonly content = input.required<HTMLElement>({ alias: 'opWpTableCellContent' });

  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef).nativeElement;

  constructor() {
    effect(() => this.host.replaceChildren(this.content()));
  }
}
