//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

import {ConfigurationService} from '../../common/config/configuration.service';
import {TimezoneService} from 'core-components/datetime/timezone.service';

export class DatePicker {
  public datepickerFormat = 'yy-mm-dd';

  private datepickerCont: JQuery = jQuery(this.datepickerElem);
  private datepickerInstance:any = null;

  constructor(readonly ConfigurationService:ConfigurationService,
              readonly timezoneService:TimezoneService,
              private datepickerElem:JQuery,
              private date:any,
              private options:any) {
    this.initialize(options);
  }

  private initialize(options:any) {
    const firstDayOfWeek = this.ConfigurationService.startOfWeekPresent() ?
      this.ConfigurationService.startOfWeek() : (jQuery.datepicker as any)._defaults.firstDay;

    var mergedOptions = _.extend({}, options, {
      firstDay: firstDayOfWeek,
      showWeeks: true,
      changeMonth: true,
      changeYear: true,
      dateFormat: this.datepickerFormat,
      defaultDate: this.timezoneService.formattedISODate(this.date),
      showButtonPanel: true
    });

    this.datepickerInstance = this.datepickerCont.datepicker(mergedOptions);

    // Disable autocomplete to avoid overlay
    this.datepickerCont.attr('autocomplete', 'off');
  }

  public clear() {
    this.datepickerInstance.datepicker('setDate', null);
  }

  public destroy() {
    this.hide();
    this.datepickerInstance.datepicker('destroy');
  }

  public hide() {
    this.datepickerInstance.datepicker('hide');
    this.datepickerCont.scrollParent().off('scroll');
  }

  public show() {
    this.datepickerInstance.datepicker('show');
    this.hideDuringScroll();
  }

  public reshow() {
    this.datepickerInstance.datepicker('show');
  }

  private hideDuringScroll() {
    let reshowTimeout:any = null;
    let scrollParent = this.datepickerCont.scrollParent();

    scrollParent.scroll(() => {
      this.datepickerInstance.datepicker('hide');
      if (reshowTimeout) {
        clearTimeout(reshowTimeout);
      }

      reshowTimeout = setTimeout(() => {
        if (this.visibleAndActive()) {
          this.datepickerInstance.datepicker('show');
        }
      }, 50);
    });
  }

  private visibleAndActive() {
    var input = this.datepickerCont;
    return document.elementFromPoint(input.offset()!.left, input.offset()!.top) === input[0] &&
      document.activeElement === input[0];
  };
}
