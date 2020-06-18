//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

import {Injectable} from '@angular/core';
import {DateKeys} from "core-components/datepicker/datepicker.modal";
import {DatePicker} from "core-app/modules/common/op-date-picker/datepicker";

@Injectable({ providedIn: 'root' })
export class DatepickerHelper {
  public currentlyActivatedDateField:DateKeys;

  /**
   * Map the date to the internal format,
   * setting to null if it's empty.
   * @param key
   */
  public mappedDate(date:string):string|null {
    return date === '' ? null : date;
  }

  public parseDate(date:Date|string):Date|'' {
    if (date instanceof Date) {
      return date;
    } else if (date === '') {
      return '';
    } else {
      return new Date(date);
    }
  }

  public validDate(date:Date|string) {
    return (date instanceof Date) ||
      (date === '') ||
      !!new Date(date).valueOf();
  }

  public setCurrentActivatedField(val:DateKeys) {
    this.currentlyActivatedDateField = val;
  }

  public toggleCurrentActivatedField(dates:{ [key in DateKeys]:string }, datePicker:DatePicker) {
    this.currentlyActivatedDateField = this.currentlyActivatedDateField === 'start' ? 'end' : 'start';
    this.setDatepickerRestrictions(dates, datePicker);
  }

  public isStateOfCurrentActivatedField(val:DateKeys):boolean {
    return this.currentlyActivatedDateField === val;
  }

  public setDatepickerRestrictions(dates:{ [key in DateKeys]:string }, datePicker:DatePicker) {
    if (this.isStateOfCurrentActivatedField('start')) {
      datePicker.datepickerInstance.set('minDate', null);
      datePicker.datepickerInstance.set('maxDate', dates.end);
    } else {
      datePicker.datepickerInstance.set('minDate', dates.start);
      datePicker.datepickerInstance.set('maxDate', null);
    }
  }

  public setRangeClasses(dates:{ [key in DateKeys]:string }, datePickerInstance:DatePicker) {
    if (!dates.start || !dates.end) {
      return;
    }

    var selectedElements = document.getElementsByClassName('flatpickr-day selected');
    if (selectedElements.length === 2) {
      selectedElements[0].classList.add('startRange');
      selectedElements[1].classList.add('endRange');

      this.selectRangeFromUntil(selectedElements[0], selectedElements[1]);
    } else if (selectedElements.length === 1) {
      // Date range needs to be shown over multiple months
      if (this.datepickerShowsDate(dates.start, datePickerInstance)) {
        selectedElements[0].classList.add('startRange');
        this.selectRangeFromUntil(selectedElements[0], '');
      } else if (this.datepickerShowsDate(dates.end, datePickerInstance)) {
        selectedElements[0].classList.add('endRange');

        let firstDay = jQuery('.flatpickr-days .flatpickr-day')[0];
        firstDay.classList.add('inRange');
        this.selectRangeFromUntil(firstDay, selectedElements[0]);
      }
    } else if (this.datepickerIsInDateRange(dates, datePickerInstance)) {
      jQuery('.dayContainer .flatpickr-day').addClass('inRange');
    }
  }

  private datepickerShowsDate(date:string, datePickerInstance:DatePicker):boolean {
    return datePickerInstance.datepickerInstance.currentMonth === new Date(date).getMonth() &&
      datePickerInstance.datepickerInstance.currentYear === new Date(date).getFullYear();
  }

  private datepickerIsInDateRange(dates:{ [key in DateKeys]:string }, datePickerInstance:DatePicker):boolean {
    return datePickerInstance.datepickerInstance.currentYear <= new Date(dates.end).getFullYear() &&
           datePickerInstance.datepickerInstance.currentMonth < new Date(dates.end).getMonth() &&
           datePickerInstance.datepickerInstance.currentYear >= new Date(dates.start).getFullYear() &&
           datePickerInstance.datepickerInstance.currentMonth > new Date(dates.start).getMonth();
  }

  private selectRangeFromUntil(from:Element, until:string|Element) {
    jQuery(from).nextUntil(until).addClass('inRange');
  }
}
