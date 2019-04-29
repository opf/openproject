// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Component, ElementRef, OnInit} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {DynamicCssService} from "core-app/modules/common/dynamic-css/dynamic-css.service";

@Component({
  template: `
    <ng-select [items]="options"
               [virtualScroll]="true"
               bindLabel="name"
               bindValue="value"
               [(ngModel)]="selectedColor"
               appendTo="body">
      <ng-template ng-label-tmp let-item="item">
        <span [ngClass]="highlightColor(item)">{{item.name}}</span>
      </ng-template>
      <ng-template ng-option-tmp let-item="item" let-index="index">
        <span [ngClass]="highlightColor(item)">{{item.name}}</span>
      </ng-template>
    </ng-select>
  `,
  selector: 'colors-autocompleter'
})
export class ColorsAutocompleter implements OnInit {
  public options:any[];
  public selectedColor:any;
  public highlightTextInline:boolean = false;

  constructor(protected elementRef:ElementRef,
              protected readonly dynamicCssService:DynamicCssService) {
  }

  ngOnInit() {
    this.dynamicCssService.requireHighlighting();
    this.options = JSON.parse(this.elementRef.nativeElement.dataset.colors);
    this.highlightTextInline =  JSON.parse(this.elementRef.nativeElement.dataset.highlighttextinline);
    this.selectedColor = this.options.find((item) => item.selected === true).value;
  }

  private highlightColor(item:any) {
    let highlightingClass;
    if (this.highlightTextInline) {
      highlightingClass = '__hl_inline_type_ ';
    } else {
      highlightingClass = '__hl_inline_ ';
    }
    return highlightingClass + Highlighting.colorClass(this.highlightTextInline, item.value);
  }

}

DynamicBootstrapper.register({ selector: 'colors-autocompleter', cls: ColorsAutocompleter });

