//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { Component, ElementRef, OnInit } from '@angular/core';
import { Highlighting } from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";

export const colorsAutocompleterSelector = 'colors-autocompleter';

@Component({
  template: `
    <ng-select [items]="options"
               [virtualScroll]="true"
               bindLabel="name"
               bindValue="value"
               [(ngModel)]="selectedOption"
               (change)="onModelChange($event)"
               [clearable]="false"
               appendTo="body">
      <ng-template ng-label-tmp let-item="item">
        <span [ngClass]="highlightColor(item)">{{item.name}}</span>
      </ng-template>
      <ng-template ng-option-tmp let-item="item" let-index="index">
        <span [ngClass]="highlightColor(item)">{{item.name}}</span>
      </ng-template>
    </ng-select>
  `,
  selector: colorsAutocompleterSelector
})
export class ColorsAutocompleter implements OnInit {
  public options:any[];
  public selectedOption:any;
  private highlightTextInline = false;
  private updateInputField:HTMLInputElement|undefined;
  private selectedColorId:string;

  constructor(protected elementRef:ElementRef,
              protected readonly I18n:I18nService) {
  }

  ngOnInit() {
    this.setColorOptions();

    this.updateInputField = document.getElementsByName(this.elementRef.nativeElement.dataset.updateInput)[0] as HTMLInputElement|undefined;
    this.highlightTextInline =  JSON.parse(this.elementRef.nativeElement.dataset.highlightTextInline);
  }

  public onModelChange(color:any) {
    if (color && this.updateInputField) {
      this.updateInputField.value = color.value;
    }
  }

  private setColorOptions() {
    this.options = JSON.parse(this.elementRef.nativeElement.dataset.colors);
    this.options.unshift({ name: this.I18n.t('js.label_no_color'), value: '' });

    this.selectedOption = this.options.find((item) => item.selected === true);

    if (this.selectedOption) {
      this.selectedOption = this.selectedOption.value;
    } else {
      // Differentiate between "No color" and a color that is now not selectable any more
      this.selectedColorId = this.elementRef.nativeElement.dataset.selectedColor;
      this.selectedOption = this.selectedColorId ? this.selectedColorId : '';
    }
  }

  private highlightColor(item:any) {
    if (item.value === '') {
      return;
    }

    let highlightingClass;
    if (this.highlightTextInline) {
      highlightingClass = '__hl_inline_type_ ';
    } else {
      highlightingClass = '__hl_inline_ ';
    }
    return highlightingClass + Highlighting.colorClass(this.highlightTextInline, item.value);
  }

}


