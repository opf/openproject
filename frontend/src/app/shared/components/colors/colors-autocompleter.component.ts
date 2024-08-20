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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, ElementRef, OnInit } from '@angular/core';
import {
  Highlighting,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { I18nService } from 'core-app/core/i18n/i18n.service';

interface ColorItem {
  name:string;
  value:string;
  selected?:boolean;
}

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
        <span [ngClass]="highlightColor(item)">{{ item.name }}</span>
      </ng-template>
      <ng-template ng-option-tmp let-item="item" let-index="index">
        <span [ngClass]="highlightColor(item)">{{ item.name }}</span>
      </ng-template>
    </ng-select>
  `,
  selector: 'opce-colors-autocompleter',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ColorsAutocompleterComponent implements OnInit {
  public options:ColorItem[];

  public selectedOption?:ColorItem|string;

  private highlightTextInline = false;

  private updateInputField:HTMLInputElement|undefined;

  private selectedColorId:string;

  constructor(
    protected elementRef:ElementRef<HTMLElement>,
    protected readonly I18n:I18nService,
  ) {
  }

  ngOnInit() {
    this.setColorOptions();

    this.updateInputField = document.getElementsByName(this.elementRef.nativeElement.dataset.updateInput as string)[0] as HTMLInputElement|undefined;
    this.highlightTextInline = JSON.parse(this.elementRef.nativeElement.dataset.highlightTextInline as string) as boolean;
  }

  public onModelChange(color:{ name:string, value:string }) {
    if (color && this.updateInputField) {
      this.updateInputField.value = color.value;
    }
  }

  private setColorOptions() {
    this.options = JSON.parse(this.elementRef.nativeElement.dataset.colors as string) as {
      name:string,
      value:string
    }[];
    this.options.unshift({ name: this.I18n.t('js.label_no_color'), value: '' });

    this.selectedOption = this.options.find((item) => item.selected === true);

    if (this.selectedOption) {
      this.selectedOption = this.selectedOption.value;
    } else {
      // Differentiate between "No color" and a color that is now not selectable any more
      this.selectedColorId = this.elementRef.nativeElement.dataset.selectedColor as string;
      this.selectedOption = this.selectedColorId ? this.selectedColorId : '';
    }
  }

  highlightColor(item:ColorItem):string|undefined {
    if (item.value === '') {
      return undefined;
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
