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

import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Injector,
  Input,
  Output,
  ViewChild,
} from '@angular/core';
import { NgSelectComponent } from '@ng-select/ng-select';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpInviteUserModalService } from 'core-app/features/invite-user-modal/invite-user-modal.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { AddTagFn } from '@ng-select/ng-select/lib/ng-select.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { Subject } from 'rxjs';
import { typeFromHref } from 'core-app/shared/components/principal/principal-helper';
import { compareByHref } from 'core-app/shared/helpers/angular/tracking-functions';
import { filter } from 'rxjs/operators';
import { repositionDropdownBugfix } from 'core-app/shared/components/autocompleter/op-autocompleter/autocompleter.helper';

export interface CreateAutocompleterValueOption {
  name:string;
  href:string|null;
}

@Component({
  templateUrl: './create-autocompleter.component.html',
  selector: 'create-autocompleter',
  styleUrls: ['./create-autocompleter.component.sass'],
})
export class CreateAutocompleterComponent extends UntilDestroyedMixin implements AfterViewInit {
  @Input() public availableValues:CreateAutocompleterValueOption[];

  @Input() public appendTo:string;

  @Input() public resource:HalResource;

  @Input() public model:any;

  @Input() public required = false;

  @Input() public disabled = false;

  @Input() public finishedLoading = false;

  @Input() public id = '';

  @Input() public classes = '';

  @Input() public typeahead?:Subject<string>;

  @Input() public hideSelected = false;

  @Output() public onChange = new EventEmitter<HalResource>();

  @Output() public onKeydown = new EventEmitter<JQuery.TriggeredEvent>();

  @Output() public onOpen = new EventEmitter<void>();

  @Output() public onClose = new EventEmitter<void>();

  @Output() public onAfterViewInit = new EventEmitter<this>();

  @Output() public onAddNew = new EventEmitter<HalResource>();

  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  @InjectField() readonly I18n:I18nService;

  @InjectField() readonly cdRef:ChangeDetectorRef;

  @InjectField() readonly currentProject:CurrentProjectService;

  @InjectField() readonly pathHelper:PathHelperService;

  public compareByHref = compareByHref;

  public text:{ [key:string]:string } = {};

  public createAllowed:boolean|AddTagFn = false;

  private _openDirectly = false;

  constructor(readonly injector:Injector) {
    super();

    this.text.add_new_action = this.I18n.t('js.label_create');
  }

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
    repositionDropdownBugfix(this.ngSelectComponent);
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
}
