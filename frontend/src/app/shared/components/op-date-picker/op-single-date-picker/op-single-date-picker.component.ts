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

import { Component, Input, Output } from '@angular/core';
import { Instance } from 'flatpickr/dist/types/instance';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { DatePicker } from 'core-app/shared/components/op-date-picker/datepicker';
import { AbstractDatePickerDirective } from 'core-app/shared/components/op-date-picker/date-picker.directive';
import { DebouncedEventEmitter } from 'core-app/shared/helpers/rxjs/debounced-event-emitter';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';

@Component({
  selector: 'op-single-date-picker',
  templateUrl: './op-single-date-picker.component.html',
})
export class OpSingleDatePickerComponent extends AbstractDatePickerDirective {
  @Output() public changed = new DebouncedEventEmitter<string>(componentDestroyed(this));

  @Input() public initialDate = '';

  onInputChange():void {
    if (this.inputIsValidDate()) {
      this.changed.emit(this.currentValue);
    } else {
      this.changed.emit('');
    }
  }

  protected inputIsValidDate():boolean {
    return (/\d{4}-\d{2}-\d{2}/.exec(this.currentValue)) !== null;
  }

  protected initializeDatepicker():void {
    const options = {
      allowInput: true,
      appendTo: this.appendTo,
      onChange: (selectedDates:Date[], dateStr:string) => {
        const val:string = dateStr;

        if (this.isEmpty()) {
          return;
        }

        this.inputElement.value = val;
        this.changed.emit(val);
      },
      onKeyDown: (selectedDates:Date[], dateStr:string, instance:Instance, data:KeyboardEvent) => {
        if (data.which === KeyCodes.ESCAPE) {
          this.canceled.emit();
        }
      },
    };

    let initialValue;
    if (this.isEmpty() && this.initialDate) {
      initialValue = this.timezoneService.parseISODate(this.initialDate).toDate();
    } else {
      initialValue = this.currentValue;
    }

    this.datePickerInstance = new DatePicker(
      `#${this.id}`,
      initialValue,
      options,
      null,
      this.configurationService,
    );
  }
}
