// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  Component, ElementRef, OnInit, ViewChild,
} from '@angular/core';
import { NgSelectComponent } from '@ng-select/ng-select';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IProjectAutocompleterData } from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocompleter.component';
import { IProjectAutocompleteItem } from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocomplete-item';

type SelectItem = { label:string, value:string, selected?:boolean };

export const autocompleteSelectDecorationSelector = 'autocomplete-select-decoration';

@Component({
  template: `
    <op-project-autocompleter
      *ngIf="isProjectField()"
      [value]="currentProjectSelection"
      [multiple]="multiselect"
      [labelForId]="labelForId"
      (valueChange)="updateProjectSelection($event)"
      appendTo="body"
    >
    </op-project-autocompleter>

    <ng-select
      *ngIf="!isProjectField()"
      [items]="options"
      [labelForId]="labelForId"
      bindLabel="label"
      [multiple]="multiselect"
      [virtualScroll]="true"
      [ngModel]="selected"
      appendTo="body"
      [placeholder]="text.placeholder"
      (ngModelChange)="updateSelection($event)">
      <ng-template ng-option-tmp let-item="item" let-index="index">
        {{ item.label }}
      </ng-template>
    </ng-select>
  `,
  selector: autocompleteSelectDecorationSelector,
})
export class AutocompleteSelectDecorationComponent implements OnInit {
  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  public options:SelectItem[];

  /** Whether we're a multiselect */
  public multiselect = false;

  /** Get the selected options */
  public selected:SelectItem|SelectItem[];

  /** Get the selected options especially for the project autocompleter  */
  public currentProjectSelection:{ id:string, name:string }|{ id:string, name:string }[];

  /** The input name we're syncing selections to */
  private syncInputFieldName:string;

  /** The input id used for label */
  public labelForId:string;

  /** The field key (e.g. status, type, or project)  */
  public key:string;

  text = {
    placeholder: this.I18n.t('js.placeholders.selection'),
  };

  constructor(
    protected elementRef:ElementRef,
    readonly I18n:I18nService,
  ) {
  }

  ngOnInit():void {
    const element = this.elementRef.nativeElement as HTMLElement;

    // Set options
    this.multiselect = element.dataset.multiselect === 'true';
    this.labelForId = element.dataset.inputId!;
    this.key = element.dataset.key!;

    // Get the sync target
    this.syncInputFieldName = element.dataset.inputName!;
    // Add Rails multiple identifier if multiselect
    if (this.multiselect) {
      this.syncInputFieldName += '[]';
    }

    // Prepare and build the options
    // Expected array of objects with id, name, select
    const data:SelectItem[] = JSON.parse(element.dataset.options!);

    // Set initial selection
    this.setInitialSelection(data);
    if (this.isProjectField()) {
      this.setInitialProjectSelection();
    }

    if (!this.multiselect) {
      this.selected = (this.selected as SelectItem[])[0];
    }

    this.options = data;

    // Unhide the parent
    element.parentElement!.hidden = false;
  }

  setInitialSelection(data:SelectItem[]):void {
    this.updateSelection(data.filter((element) => element.selected));
  }

  updateSelection(items:SelectItem|SelectItem[]):void {
    this.selected = items;
    items = _.castArray(items);

    this.removeCurrentSyncedFields();
    items.forEach((el:SelectItem) => {
      this.createSyncedField(el.value);
    });
  }

  createSyncedField(value:string):void {
    const element = jQuery(this.elementRef.nativeElement);
    element
      .parent()
      .append(`<input type="hidden" name="${this.syncInputFieldName || ''}" value="${value}" />`);
  }

  removeCurrentSyncedFields():void {
    const element = jQuery(this.elementRef.nativeElement);
    element
      .parent()
      .find(`input[name="${this.syncInputFieldName}"]`)
      .remove();
  }

  updateProjectSelection(items:IProjectAutocompleteItem|IProjectAutocompleteItem[]):void {
    items = _.castArray(items);
    const mappedItems = items.map(item => {
      const selectedItem:SelectItem = {
        label: item.name,
        value: item.id.toString(),
        selected: true,
      };

      return selectedItem;
    });

    this.updateSelection(mappedItems);
  }

  setInitialProjectSelection():void {
    const items = _.castArray(this.selected);
    if (items.length === 0) return;

    if (this.multiselect) {
      this.currentProjectSelection = items.map((item:SelectItem) => ({
        id: item.value,
        name: item.label,
      }));
    } else {
      this.currentProjectSelection = {
        id: items[0].value,
        name: items[0].label,
      };
    }
  }

  isProjectField():boolean {
    return this.key === 'project';
  }
}
