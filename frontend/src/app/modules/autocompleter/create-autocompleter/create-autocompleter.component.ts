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

import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  Output,
  ViewChild
} from '@angular/core';
import { NgSelectComponent } from "@ng-select/ng-select";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { AddTagFn } from "@ng-select/ng-select/lib/ng-select.component";
import { Subject } from 'rxjs';

export interface CreateAutocompleterValueOption {
  name:string;
  $href:string|null;
}

@Component({
  templateUrl: './create-autocompleter.component.html',
  selector: 'create-autocompleter',
  styleUrls: ['./create-autocompleter.component.sass']
})
export class CreateAutocompleterComponent implements AfterViewInit {
  @Input() public availableValues:CreateAutocompleterValueOption[];
  @Input() public appendTo:string;
  @Input() public model:any;
  @Input() public required = false;
  @Input() public disabled = false;
  @Input() public finishedLoading = false;
  @Input() public id = '';
  @Input() public classes = '';
  @Input() public typeahead?:Subject<string>;
  @Input() public hideSelected = false;
  @Input() public showAddNewButton:boolean;

  @Output() public onChange = new EventEmitter<HalResource>();
  @Output() public onKeydown = new EventEmitter<JQuery.TriggeredEvent>();
  @Output() public onOpen = new EventEmitter<void>();
  @Output() public onClose = new EventEmitter<void>();
  @Output() public onAfterViewInit = new EventEmitter<this>();
  @Output() public onAddNew = new EventEmitter<this>();


  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  public text:{ [key:string]:string } = {
    add_new_action: this.I18n.t('js.label_create'),
  };

  public createAllowed:boolean|AddTagFn = false;

  private _openDirectly = false;

  constructor(readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly currentProject:CurrentProjectService,
              readonly pathHelper:PathHelperService,
  ) { }

  ngAfterViewInit() {
    this.onAfterViewInit.emit(this);
  }

  public openSelect() {
    if (this.ngSelectComponent) {
      this.ngSelectComponent.open();
    } else {
      // In case the autocompleter was not loaded,
      // do not reset the variable
      return;
    }

    this.openDirectly = false;
  }

  public closeSelect() {
    this.ngSelectComponent && this.ngSelectComponent.close();
  }

  public changeModel(element:HalResource) {
    this.onChange.emit(element);
  }

  public opened() {
    // Force reposition as a workaround for BUG
    // https://github.com/ng-select/ng-select/issues/1259
    setTimeout(() => {
      const component = this.ngSelectComponent as any;
      if (this.appendTo && component && component.dropdownPanel) {
        component.dropdownPanel._updatePosition();
      }
    }, 25);

    this.onOpen.emit();
  }

  public closed() {
    this.openDirectly = false;
    this.onClose.emit();
  }

  public keyPressed(event:JQuery.TriggeredEvent) {
    this.onKeydown.emit(event);
  }

  public get openDirectly() {
    return this._openDirectly;
  }

  public set openDirectly(val:boolean) {
    this._openDirectly = val;
    if (val) {
      this.openSelect();
    }
  }

  public focusInputField() {
    this.ngSelectComponent && this.ngSelectComponent.focus();
  }

  public onUserInvited(user:HalResource) {
    this.onChange.emit(user);
  }
}
