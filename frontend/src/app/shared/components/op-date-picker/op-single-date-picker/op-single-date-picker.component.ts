// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
  Component,
  EventEmitter,
  Input,
  Output,
  OnDestroy,
  forwardRef,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

/* eslint-disable-next-line change-detection-strategy/on-push */
@Component({
  selector: 'op-single-date-picker',
  templateUrl: './op-single-date-picker.component.html',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => OpSingleDatePickerComponent),
      multi: true,
    },
  ],
})
export class OpSingleDatePickerComponent implements ControlValueAccessor, OnDestroy {
  @Output() public changed = new EventEmitter();

  @Output() public blurred = new EventEmitter<string>();

  @Output() public enterPressed = new EventEmitter<string>();

  @Input() public value = '';

  @Input() public id = '';

  @Input() public name = '';

  @Input() public required = false;

  @Input() public size = 20;

  @Input() public disabled = false;

  currentValue = '';

  isOpen = false;

  constructor(
    protected timezoneService:TimezoneService,
  ) {}

  open() {
    this.isOpen = true;
  }

  close() {
    this.isOpen = false;
  }

  protected inputIsValidDate():boolean {
    return (/\d{4}-\d{2}-\d{2}/.exec(this.currentValue)) !== null;
  }

  public formatter(data:string):string {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      const d = this.timezoneService.parseDate(data);

      return this.timezoneService.formattedISODate(d);
    }
    return data;
  }

  ngOnDestroy():void {
  }

  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  onControlChange:(_?:unknown) => void = () => { };

  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  onControlTouch:(_?:unknown) => void = () => { };

  writeValue(date:string):void {
    this.value = date; //this.formatter(date);
  }

  registerOnChange(fn:(_:unknown) => void):void {
    this.onControlChange = fn;
  }

  registerOnTouched(fn:(_:unknown) => void):void {
    this.onControlTouch = fn;
  }

  setDisabledState(disabled:boolean):void {
    this.disabled = disabled;
  }
}
