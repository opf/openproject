// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

import {AfterViewInit, Component, EventEmitter, Input, Output, ViewChild} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {NgSelectComponent} from "@ng-select/ng-select/dist";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Component({
  template: `
    <ng-select *ngIf="createAllowed"
               #addActionAttributeSelect
               [(ngModel)]="model"
               [items]="availableValues"
               [addTag]="createNewElement.bind(this)"
               [virtualScroll]="true"
               [required]="required"
               [clearable]="!required"
               [disabled]="disabled"
               [appendTo]="appendTo"
               [id]="id"
               (change)="changeModel($event)"
               (open)="opened()"
               (close)="closed()"
               (keydown)="keyPressed($event)"
               bindLabel="name">
      <ng-template ng-tag-tmp let-search="searchTerm">
        <b [textContent]="text.add_new_action"></b>: {{search}}
      </ng-template>
    </ng-select>

    <ng-select *ngIf="!createAllowed"
               #actionAttributeSelect
               [(ngModel)]="model"
               [items]="availableValues"
               [virtualScroll]="true"
               [required]="required"
               [clearable]="!required"
               [disabled]="disabled"
               [appendTo]="appendTo"
               [id]="id"
               (change)="changeModel($event)"
               (open)="opened()"
               (close)="closed()"
               (keydown)="keyPressed($event)"
               bindLabel="name">
    </ng-select>
  `,
  selector: 'create-autocompleter'
})
export class CreateAutocompleterComponent implements AfterViewInit {
  @ViewChild('addActionAttributeSelect') public addAutoCompleter:NgSelectComponent;
  @ViewChild('actionAttributeSelect') public autoCompleter:NgSelectComponent;

  @Input() public availableValues:any[];
  @Input() public appendTo:string;
  @Input() public model:any;
  @Input() public required:boolean = false;
  @Input() public disabled:boolean = false;
  @Input() public id:string = '';
  @Input() public set createAllowed(val:boolean) {
    this._createAllowed = val;
    setTimeout(() => {
      this.focusInputField();
    });
  }

  @Output() public onCreate = new EventEmitter<string>();
  @Output() public onChange = new EventEmitter<HalResource>();
  @Output() public onKeydown = new EventEmitter<JQueryEventObject>();
  @Output() public onOpen = new EventEmitter<void>();
  @Output() public onClose = new EventEmitter<void>();
  @Output() public onAfterViewInit = new EventEmitter<CreateAutocompleterComponent>();

  private _createAllowed:boolean = false;

  public text:any = {
    add_new_action: this.I18n.t('js.label_create_new'),
  };

  constructor(readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              readonly pathHelper:PathHelperService) {
  }

  ngAfterViewInit() {
    this.focusInputField();
    this.onAfterViewInit.emit(this);
  }

  public openSelect() {
    this.createAllowed ? this.addAutoCompleter.open() : this.autoCompleter.open();
  }

  public createNewElement(name:string) {
    this.onCreate.emit(name);
  }

  public changeModel(element:HalResource) {
    this.onChange.emit(element);
  }

  public opened() {
    this.onOpen.emit();
  }

  public closed() {
    this.onClose.emit();
  }

  public keyPressed(event:JQueryEventObject) {
    this.onKeydown.emit(event);
  }

  public get createAllowed() {
    return this._createAllowed;
  }

  private focusInputField() {
    this.createAllowed ? this.addAutoCompleter.focus() : this.autoCompleter.focus();
  }
}

DynamicBootstrapper.register({ selector: 'add-attribute-autocompleter', cls: CreateAutocompleterComponent  });
