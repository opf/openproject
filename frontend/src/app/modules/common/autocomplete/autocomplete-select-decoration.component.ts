// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Component, ElementRef, OnInit, ViewChild} from '@angular/core';
import {NgSelectComponent} from "@ng-select/ng-select";

type SelectItem = { label:string, value:string, selected?:boolean };

export const autocompleteSelectDecorationSelector = 'autocomplete-select-decoration';

@Component({
  template: `
    <ng-select [items]="options"
               [labelForId]="labelForId"
               bindLabel="label"
               [multiple]="multiselect"
               [virtualScroll]="true"
               [ngModel]="selected"
               appendTo="body"
               placeholder="Please select"
               (ngModelChange)="updateSelection($event)">
      <ng-template ng-option-tmp let-item="item" let-index="index">
        {{ item.label }}
      </ng-template>
    </ng-select>
  `,
  selector: autocompleteSelectDecorationSelector
})
export class AutocompleteSelectDecorationComponent implements OnInit {
  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  public options:SelectItem[];

  /** Whether we're a multiselect */
  public multiselect:boolean = false;

  /** Get the selected options */
  public selected:SelectItem|SelectItem[];

  /** The input name we're syncing selections to */
  private syncInputFieldName:string;

  /** The input id used for label */
  public labelForId:string;

  constructor(protected elementRef:ElementRef) {
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;

    // Set options
    this.multiselect = element.dataset.multiselect === 'true';
    this.labelForId = element.dataset.inputId!;

    // Get the sync target
    this.syncInputFieldName = element.dataset.inputName;
    // Add Rails multiple identifier if multiselect
    if (this.multiselect) {
      this.syncInputFieldName += '[]';
    }

    // Prepare and build the options
    // Expected array of objects with id, name, select
    const data:SelectItem[] = JSON.parse(element.dataset.options);

    // Set initial selection
    this.setInitialSelection(data);

    if (!this.multiselect) {
      this.selected = (this.selected as SelectItem[])[0];
    }

    this.options = data;

    // Unhide the parent
    element.parentElement.hidden = false;
  }

  setInitialSelection(data:SelectItem[]) {
    this.updateSelection(data.filter(element => element.selected));
  }

  updateSelection(items:SelectItem|SelectItem[]) {
    this.selected = items;
    items = _.castArray(items) as SelectItem[];

    this.removeCurrentSyncedFields();
    items.forEach((el:SelectItem) => {
      this.createSyncedField(el.value);
    });
  }

  createSyncedField(value:string) {
    const element = jQuery(this.elementRef.nativeElement);
    element
      .parent()
      .append(`<input type="hidden" name="${this.syncInputFieldName || ''}" value="${value}" />`);
  }

  removeCurrentSyncedFields() {
    const element = jQuery(this.elementRef.nativeElement);
    element
      .parent()
      .find(`input[name="${this.syncInputFieldName}"]`)
      .remove();
  }
}
