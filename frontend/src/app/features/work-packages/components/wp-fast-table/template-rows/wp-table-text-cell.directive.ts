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

import { ChangeDetectorRef, Directive, DestroyRef, ElementRef, inject, input, signal } from '@angular/core';
import { TextCellPresentation } from './text-cell-presentation';
import { templateCellEditors } from './template-cell-editing';

@Directive({
  selector: 'td[opWpTableTextCell], th[opWpTableTextCell]',
  exportAs: 'opWpTableTextCell',
  host: {
    class: 'wp-table--cell-td wp-table--navigable-cell',
    '[class]': 'presentation().attribute',
    '[class.-no-ellipsis]': '["startDate", "dueDate", "duration"].includes(presentation().attribute)',
    '[class.-min-200]': '["estimatedTime", "remainingTime"].includes(presentation().attribute)',
    '[class.-max]': 'presentation().attribute === "subject"',
    '[attr.data-row-header-name]': 'presentation().attribute === "subject" ? presentation().text : null',
  },
})
export class WorkPackageTableTextCellDirective {
  readonly presentation = input.required<TextCellPresentation>();
  readonly editing = signal(false);
  private readonly cell = inject<ElementRef<HTMLTableCellElement>>(ElementRef).nativeElement;
  private readonly cdRef = inject(ChangeDetectorRef);

  constructor() {
    templateCellEditors.set(this.cell, this);
    inject(DestroyRef).onDestroy(() => templateCellEditors.delete(this.cell));
  }

  beginEdit():HTMLElement {
    this.editing.set(true);
    this.cdRef.detectChanges();
    return this.cell.querySelector<HTMLElement>(':scope > .inline-edit--container')!;
  }

  endEdit():void {
    this.editing.set(false);
    this.cdRef.detectChanges();
  }
}
