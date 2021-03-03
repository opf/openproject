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

import { Injectable } from '@angular/core';
import { DateKeys } from "core-components/datepicker/datepicker.modal";
import { DatePicker } from "core-app/modules/common/op-date-picker/datepicker";
import { DateOption } from "flatpickr/dist/types/options";

@Injectable({ providedIn: 'root' })
export class DatePickerModalHelper {
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
      return new Date(date.setHours(0,0,0,0));
    } else if (date === '') {
      return '';
    } else {
      return new Date(new Date(date).setHours(0,0,0,0));
    }
  }

  public validDate(date:Date|string) {
    return (date instanceof Date) ||
      (date === '') ||
      !!new Date(date).valueOf();
  }

  public sortDates(dates:Date[]):Date[] {
    return dates.sort(function(a:Date, b:Date) {
      return a.getTime() - b.getTime();
    });
  }

  public areDatesEqual(firstDate:Date|string, secondDate:Date|string) {
    const parsedDate1 = this.parseDate(firstDate);
    const parsedDate2 = this.parseDate(secondDate);

    if ((typeof(parsedDate1) === 'string') || (typeof(parsedDate2) === 'string')) {
      return false;
    } else {
      return parsedDate1.getTime() === parsedDate2.getTime();
    }
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

  public setDates(dates:DateOption|DateOption[], datePicker:DatePicker, enforceDate?:Date) {
    const currentMonth = datePicker.datepickerInstance.currentMonth;
    const currentYear = datePicker.datepickerInstance.currentYear;
    datePicker.setDates(dates);

    if (enforceDate) {
      datePicker.datepickerInstance.currentMonth = enforceDate.getMonth();
      datePicker.datepickerInstance.currentYear = enforceDate.getFullYear();
    } else {
      // Keep currently active month and avoid jump because of two-month layout
      datePicker.datepickerInstance.currentMonth = currentMonth;
      datePicker.datepickerInstance.currentYear = currentYear;
    }

    datePicker.datepickerInstance.redraw();
  }

  public setDatepickerRestrictions(dates:{ [key in DateKeys]:string }, datePicker:DatePicker) {
    if (!dates.start && !dates.end) {
      return;
    }

    let disableFunction:Function = (date:Date) => {
      return false;
    };

    if (this.isStateOfCurrentActivatedField('start') && dates.end) {
      disableFunction = (date:Date) => {
        return date.getTime() > new Date(dates.end).setHours(0,0,0,0);
      };
    } else if (this.isStateOfCurrentActivatedField('end') && dates.start) {
      disableFunction = (date:Date) => {
        return date.getTime() < new Date(dates.start).setHours(0,0,0,0);
      };
    }

    datePicker.datepickerInstance.set('disable', [disableFunction]);
  }

  public setRangeClasses(dates:{ [key in DateKeys]:string }) {
    if (!dates.start || !dates.end || (dates.start === dates.end)) {
      return;
    }

    var monthContainer = document.getElementsByClassName('dayContainer');
    // For each container of the two-month layout, set the highlighting classes
    for (let i = 0; i < monthContainer.length; i++) {
      this.highlightRangeInSingleMonth(monthContainer[i], dates);
    }
  }

  private highlightRangeInSingleMonth(container:Element, dates:{ [key in DateKeys]:string }) {
    var selectedElements = jQuery(container).find('.flatpickr-day.selected');
    if (selectedElements.length === 2) {
      // Both dates are in the same month
      selectedElements[0].classList.add('startRange');
      selectedElements[1].classList.add('endRange');

      this.selectRangeFromUntil(selectedElements[0], selectedElements[1]);
    } else if (selectedElements.length === 1) {
      // Only one date is in this month
      if (this.datepickerShowsDate(dates.start, selectedElements[0])) {
        selectedElements[0].classList.add('startRange');
        this.selectRangeFromUntil(selectedElements[0], '');
      } else if (this.datepickerShowsDate(dates.end, selectedElements[0])) {
        const firstDay = jQuery(container).find('.flatpickr-day')[0];

        selectedElements[0].classList.add('endRange');
        firstDay.classList.add('inRange');

        this.selectRangeFromUntil(firstDay, selectedElements[0]);
      }
    } else if (this.datepickerIsInDateRange(container, dates)) {
      // No date is in this month, but the month is completely between start and end date
      jQuery(container).find('.flatpickr-day').addClass('inRange');
    }
  }

  private datepickerShowsDate(date:string, selectedElement:Element):boolean {
    return new Date(selectedElement.getAttribute('aria-label')!).toDateString() === new Date(date).toDateString();
  }

  private datepickerIsInDateRange(container:Element, dates:{ [key in DateKeys]:string }):boolean {
    var firstDayOfMonthElement = jQuery(container).find('.flatpickr-day:not(.hidden)')[0];
    var firstDayOfMonth = new Date(firstDayOfMonthElement.getAttribute('aria-label')!);

    return firstDayOfMonth <= new Date(dates.end) &&
           firstDayOfMonth >= new Date(dates.start);
  }

  private selectRangeFromUntil(from:Element, until:string|Element) {
    jQuery(from).nextUntil(until).addClass('inRange');
  }
}
