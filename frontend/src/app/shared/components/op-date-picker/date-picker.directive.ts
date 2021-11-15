// -- copyright
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  AfterViewInit,
  Directive,
  ElementRef,
  EventEmitter,
  Input,
  OnDestroy,
  Output,
  ViewChild,
} from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DatePicker } from 'core-app/shared/components/op-date-picker/datepicker';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Directive()
export abstract class AbstractDatePickerDirective extends UntilDestroyedMixin implements OnDestroy, AfterViewInit {
  @Output() public canceled = new EventEmitter<string>();

  @Input() public appendTo?:HTMLElement;

  @Input() public classes = '';

  @Input() public id = '';

  @Input() public name = '';

  @Input() public required = false;

  @Input() public size = 20;

  @Input() public disabled = false;

  @ViewChild('dateInput') dateInput:ElementRef;

  protected datePickerInstance:DatePicker;

  public constructor(
    protected timezoneService:TimezoneService,
    protected configurationService:ConfigurationService,
  ) {
    super();

    if (!this.id) {
      this.id = `datepicker-input-${Math.floor(Math.random() * 1000).toString(3)}`;
    }
  }

  ngAfterViewInit():void {
    this.initializeDatepicker();
  }

  ngOnDestroy():void {
    if (this.datePickerInstance) {
      this.datePickerInstance.destroy();
    }
  }

  openOnClick():void {
    if (!this.disabled) {
      this.datePickerInstance.show();
    }
  }

  closeOnOutsideClick(event:any):void {
    if (!(event.relatedTarget
      && this.datePickerInstance.datepickerInstance.calendarContainer.contains(event.relatedTarget))) {
      this.close();
    }
  }

  close():void {
    this.datePickerInstance.hide();
  }

  protected isEmpty():boolean {
    return this.currentValue.trim() === '';
  }

  protected get currentValue():string {
    return this.inputElement?.value || '';
  }

  protected get inputElement():HTMLInputElement {
    return this.dateInput?.nativeElement;
  }

  protected abstract initializeDatepicker():void;
}
