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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, DestroyRef, ElementRef, inject, input, signal, viewChild } from '@angular/core';
import { TextCellPresentation } from './text-cell-presentation';
import { templateCellEditors } from './template-cell-editing';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'td[opWpTableTextCell], th[opWpTableTextCell]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'wp-table--cell-td wp-table--navigable-cell',
    '[class]': 'presentation().attribute',
    '[class.-no-ellipsis]': '["startDate", "dueDate", "duration"].includes(presentation().attribute)',
    '[class.-min-200]': '["estimatedTime", "remainingTime"].includes(presentation().attribute)',
    '[class.-max]': 'presentation().attribute === "subject"',
    '[attr.data-row-header-name]': 'presentation().attribute === "subject" ? presentation().text : null',
  },
  template: `
    @if (editing()) {
      <span #editor class="wp-table--cell-container inline-edit--container" [class]="presentation().attribute"></span>
    } @else {
      <span class="wp-table--cell-container inline-edit--container" [class]="presentation().attribute">
        <span class="inline-edit--display-field"
          [class]="presentation().attribute"
          [class.-editable]="presentation().editable"
          [class.-read-only]="!presentation().editable"
          [class.-required]="presentation().required"
          [class.-placeholder]="presentation().empty"
          [attr.data-field-name]="presentation().attribute"
          [attr.title]="presentation().title"
          [attr.aria-label]="presentation().label"
        >{{ presentation().text }}</span>
      </span>
    }
  `,
})
export class WorkPackageTableTextCellComponent {
  readonly presentation = input.required<TextCellPresentation>();
  readonly editing = signal(false);
  private readonly editor = viewChild<ElementRef<HTMLElement>>('editor');
  private readonly cdRef = inject(ChangeDetectorRef);

  constructor() {
    const cell = inject<ElementRef<HTMLTableCellElement>>(ElementRef).nativeElement;
    templateCellEditors.set(cell, this);
    inject(DestroyRef).onDestroy(() => templateCellEditors.delete(cell));
  }

  beginEdit():HTMLElement {
    this.editing.set(true);
    this.cdRef.detectChanges();
    return this.editor()!.nativeElement;
  }

  endEdit():void {
    this.editing.set(false);
    this.cdRef.detectChanges();
  }
}
