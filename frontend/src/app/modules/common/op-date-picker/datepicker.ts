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

import flatpickr from "flatpickr";
import {Instance} from "flatpickr/dist/types/instance";
import {ConfigurationService} from "core-app/modules/common/config/configuration.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import DateOption = flatpickr.Options.DateOption;

export class DatePicker {
  private datepickerFormat = 'Y-m-d';

  private datepickerCont:JQuery = jQuery(this.datepickerElemIdentifier);
  public datepickerInstance:Instance;

  constructor(private datepickerElemIdentifier:string,
              private date:any,
              private options:any,
              private datepickerTarget?:HTMLElement,
              private configurationService?:ConfigurationService) {
    this.initialize(options);
  }

  private initialize(options:any) {
    const I18n = new I18nService();
    const firstDayOfWeek =
      this.configurationService?.startOfWeekPresent() ? this.configurationService.startOfWeek() : 1;

    const mergedOptions = _.extend({}, options, {
      weekNumbers: true,
      dateFormat: this.datepickerFormat,
      defaultDate: this.date,
      locale: {
        weekdays: {
          shorthand: I18n.t('date.abbr_day_names'),
          longhand: I18n.t('date.day_names'),
        },
        months: {
          shorthand: (I18n.t('date.abbr_month_names') as any).slice(1),
          longhand: (I18n.t('date.month_names') as any).slice(1),
        },
        firstDayOfWeek: firstDayOfWeek,
        weekAbbreviation: I18n.t('date.abbr_week')
      },
    });

    var datePickerInstances:Instance|Instance[];
    if (this.datepickerTarget) {
      datePickerInstances = flatpickr(this.datepickerTarget as Node, mergedOptions);
    } else {
      datePickerInstances = flatpickr(this.datepickerElemIdentifier, mergedOptions);
    }

    this.datepickerInstance = Array.isArray(datePickerInstances) ? datePickerInstances[0] : datePickerInstances;
  }

  public clear() {
    this.datepickerInstance.clear();
  }

  public destroy() {
    this.hide();
    this.datepickerInstance.destroy();
  }

  public hide() {
    if (this.isOpen) {
      this.datepickerInstance.close();
    }

    this.datepickerCont.scrollParent().off('scroll');
  }

  public show() {
    this.datepickerInstance.open();
    this.hideDuringScroll();
  }

  public setDates(dates:DateOption|DateOption[]) {
    this.datepickerInstance.setDate(dates);
  }

  public get isOpen():boolean {
    return this.datepickerInstance.isOpen;
  }

  private hideDuringScroll() {
    let reshowTimeout:any = null;
    let scrollParent = this.datepickerCont.scrollParent();

    scrollParent.scroll(() => {
      this.datepickerInstance.close();
      if (reshowTimeout) {
        clearTimeout(reshowTimeout);
      }

      reshowTimeout = setTimeout(() => {
        if (this.visibleAndActive()) {
          this.datepickerInstance.open();
        }
      }, 50);
    });
  }

  private visibleAndActive() {
    var input = this.datepickerCont;

    try {
      return document.elementFromPoint(input.offset()!.left, input.offset()!.top) === input[0] &&
        document.activeElement === input[0];
    } catch (e) {
      console.error("Failed to test visibleAndActive " + e)
      return false;
    }
  };
}
