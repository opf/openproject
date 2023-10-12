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

import { Directive, ElementRef, EventEmitter, Injector, Input, Output, ViewChild } from '@angular/core';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { NgSelectComponent } from '@ng-select/ng-select';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { ControlValueAccessor } from '@angular/forms';
import { ID } from '@datorama/akita';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HttpClient } from '@angular/common/http';

export interface IAutocompleteItem {
  id:ID;
  href:string|null;
}

@Directive()
export abstract class OpAutocompleterBaseDirective<T extends IAutocompleteItem = IAutocompleteItem> extends UntilDestroyedMixin implements ControlValueAccessor {
  @Input() public clearAfterSelection = false;

  @Input() public name = '';

  @Input() public url:string = this.defaultUrl();

  @Input() public filters:{ selector:string; operator:FilterOperator, values:string[] }[] = [];

  // ID that should be set on the input HTML element. It is used with
  // <label> tags that have `for=""` set
  @Input() public labelForId = '';

  // Name of the hidden input
  @Input() public inputName?:string;

  // Initial value of the hidden/selected input
  @Input() public inputValue?:string;

  // Property to bind to the hidden input
  @Input() public inputBindValue = 'id';

  @Input() public appendTo = '';

  @Input() public multiple = false;

  @Input() public openDirectly = false;

  @Input() public focusDirectly = false;

  @Input() public value:T|T[]|null = null;

  @Output() public valueChange = new EventEmitter<T|T[]|null>();

  @Output() cancel = new EventEmitter();

  @Output() public userInvited = new EventEmitter<HalResource>();

  @ViewChild(NgSelectComponent, { static: true }) public ngSelectComponent:NgSelectComponent;

  constructor(
    readonly injector:Injector,
    readonly elementRef:ElementRef,
    readonly halResourceService:HalResourceService,
    readonly http:HttpClient,
    readonly I18n:I18nService,
    readonly halNotification:HalResourceNotificationService,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
  ) {
    super();
    populateInputsFromDataset(this);
  }

  valueSelected(value:T|null) {
    this.writeValue(value);
    this.valueChange.emit(value);
  }

  writeValue(value:T|null):void {
    this.value = value;
  }

  onChange = (_:T|T[]|null):void => {
  };

  onTouched = (_:T|T[]|null):void => {
  };

  registerOnChange(fn:(_:T|T[]|null) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:T|T[]|null) => void):void {
    this.onTouched = fn;
  }

  protected abstract defaultUrl():string;
}
