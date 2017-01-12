//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

module.exports = function(TimezoneService, ConfigurationService, $timeout) {
  var datepickerFormat = 'yy-mm-dd';

  function Datepicker(datepickerElem, date, options) {
    this.date = date;
    this.datepickerCont = angular.element(datepickerElem);
    this.datepickerInstance = null;
    this.initialize(options);
  }

  Datepicker.prototype.initialize = function(options) {
    var self = this,
        firstDayOfWeek = ConfigurationService.startOfWeekPresent() ?
          ConfigurationService.startOfWeek() :
          jQuery.datepicker._defaults.firstDay;

    var mergedOptions = angular.extend({}, options, {
      firstDay: firstDayOfWeek,
      showWeeks: true,
      changeMonth: true,
      changeYear: true,
      dateFormat: datepickerFormat,
      defaultDate: TimezoneService.formattedISODate(self.date),
      showButtonPanel: true
    });

    this.datepickerInstance = this.datepickerCont.datepicker(mergedOptions);
  };

  Datepicker.prototype.clear = function() {
    this.datepickerInstance.datepicker('setDate' , null);
  };

  Datepicker.prototype.hide = function() {
    this.datepickerInstance.datepicker('hide');
    this.datepickerCont.scrollParent().off('scroll');
  };

  Datepicker.prototype.show = function() {
    this.datepickerInstance.datepicker('show');
    this.hideDuringScroll();
  };

  Datepicker.prototype.reshow = function() {
    this.datepickerInstance.datepicker('show');
  };

  Datepicker.prototype.hideDuringScroll = function() {
    var hide = jQuery.proxy(function() { this.datepickerInstance.datepicker('hide'); }, this),
        show = jQuery.proxy(function() { this.datepickerInstance.datepicker('show'); }, this),
        reshowTimeout,
        scrollParent = this.datepickerCont.scrollParent(),
        visibleAndActive = jQuery.proxy(this.visibleAndActive, this);

    scrollParent.scroll(function() {
      hide();

      $timeout.cancel(reshowTimeout);

      reshowTimeout = $timeout(function() {
        if(visibleAndActive()) {
          show();
        }
      }, 50);
    });
  };

  Datepicker.prototype.visibleAndActive = function() {
    var input = this.datepickerCont;
    return document.elementFromPoint(input.offset().left, input.offset().top) === input[0] &&
      document.activeElement === input[0];
  };

  return Datepicker;
};

