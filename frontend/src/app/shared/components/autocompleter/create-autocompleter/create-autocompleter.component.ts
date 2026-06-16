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

import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Injector, Input, Output, ViewChild, inject } from '@angular/core';
import { NgSelectComponent } from '@ng-select/ng-select';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { Subject } from 'rxjs';
import { compareByHref } from 'core-app/shared/helpers/angular/tracking-functions';
import { repositionDropdownBugfix } from 'core-app/shared/components/autocompleter/op-autocompleter/autocompleter.helper';

// eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-redundant-type-constituents
type AddTagFn = (term:string) => any | Promise<any>;

export interface CreateAutocompleterValueOption {
  name:string;
  href:string|null;
}

@Component({
  templateUrl: './create-autocompleter.component.html',
  selector: 'create-autocompleter',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['./create-autocompleter.component.sass'],
  standalone: false,
})
export class CreateAutocompleterComponent extends UntilDestroyedMixin implements AfterViewInit {
  readonly injector = inject(Injector);

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

  @Output() public onKeydown = new EventEmitter<KeyboardEvent>();

  @Output() public onOpen = new EventEmitter<void>();

  @Output() public onClose = new EventEmitter<void>();

  @Output() public onAfterViewInit = new EventEmitter<this>();

  @Output() public onAddNew = new EventEmitter<HalResource>();

  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;

  readonly I18n = inject(I18nService);

  readonly cdRef = inject(ChangeDetectorRef);

  readonly currentProject = inject(CurrentProjectService);

  readonly pathHelper = inject(PathHelperService);

  public compareByHref = compareByHref;

  public groupByFn = (_item:HalResource):string | null => null;

  public text:Record<string, string> = {};

  public createAllowed:boolean|AddTagFn = false;

  private _openDirectly = false;

  constructor() {
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

  public keyPressed(event:KeyboardEvent) {
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
