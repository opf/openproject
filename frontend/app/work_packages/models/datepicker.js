//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

module.exports = function(TimezoneService, ConfigurationService, $timeout) {
  var parseDate = TimezoneService.parseDate,
    parseISODate = TimezoneService.parseISODate,
    formattedISODate = TimezoneService.formattedISODate,
    customDateFormat = 'YYYY-MM-DD',
    datepickerFormat = 'yy-mm-dd',
    customFormattedDate = function(date) {
      return parseISODate(date).format(customDateFormat);
    },
    addButton = function(appendTo, text, className, callback) {
      return jQuery('<button>', {
          text: text
        })
        .addClass('ui-state-default ui-priority-primary ui-corner-all ' + className)
        .appendTo(appendTo)
        .on('click', callback);
    };

  function Datepicker(datepickerElem, textboxElem, date) {
    this.date = date;
    this.prevDate = customFormattedDate(this.date);
    this.datepickerCont = angular.element(datepickerElem);
    this.textbox = angular.element(textboxElem);
    this.editTimerId = 0;
    this.initialize();
    this.setDate(this.date);
  }

  Datepicker.prototype.addDoneButton = function() {
    var self = this;
    setTimeout(function() {
      var buttonPane = self.datepickerCont.find('.ui-datepicker-buttonpane');

      if (buttonPane.find('.ui-datepicker-done').length !== 0) {
        return;
      }

      addButton(buttonPane, 'Done', 'ui-datepicker-done', function(e) {
        self.onDone();
        e.preventDefault();
      });
    }, 1);
  };

  Datepicker.prototype.setDate = function(date) {
    if (date) {
      this.datepickerCont.datepicker('option', 'defaultDate', customFormattedDate(date));
      this.datepickerCont.datepicker('option', 'setDate', customFormattedDate(date));
      this.textbox.val(customFormattedDate(date));
    } else {
      this.datepickerCont.datepicker('option', 'defaultDate', null);
      this.datepickerCont.datepicker('option', 'setDate', null);
      this.textbox.val('');
      this.textbox.change();
    }
  };

  Datepicker.prototype.initialize = function() {
    var self = this,
        firstDayOfWeek = ConfigurationService.startOfWeekPresent() ? 
        ConfigurationService.startOfWeek() : 
        jQuery.datepicker._defaults.firstDay;
    this.datepickerCont.datepicker({
      firstDay: firstDayOfWeek,
      showWeeks: true,
      changeMonth: true,
      dateFormat: datepickerFormat,
      defaultDate: customFormattedDate(self.date),
      inline: true,
      showButtonPanel: true,
      beforeShow: function() {
        self.addDoneButton();
      },
      onChangeMonthYear: function() {
        self.addDoneButton();
      },
      alterOffset: function(offset) {
        var wHeight = angular.element(window).height(),
          dpHeight = angular.element('#ui-datepicker-div').height(),
          inputTop = self.datepickerCont.offset().top,
          inputHeight = self.datepickerCont.innerHeight();

        if ((inputTop + inputHeight + dpHeight) > wHeight) {
          offset.top -= inputHeight - 4;
        }
        return offset;
      },
      onSelect: function(selectedDate) {
        console.log(arguments);
        if (!selectedDate || selectedDate === '' || selectedDate === self.prevDate) {
          return;
        }
        self.prevDate = parseDate(selectedDate, customDateFormat);
        $timeout(function() {
          self.onChange(formattedISODate(self.prevDate));
        });
        self.textbox.focus();
        self.datepickerCont.hide();
        self.addDoneButton();
      }
    });
  };

  Datepicker.prototype.hide = function() {
    this.datepickerCont.hide();
  };

  Datepicker.prototype.show = function() {
    this.datepickerCont.show();
  };

  Datepicker.prototype.focus = function() {
    this.textbox.click().focus();
  };

  Datepicker.prototype.onChange = angular.noop;
  Datepicker.prototype.onDone = angular.noop;
  Datepicker.prototype.onEdit = function() {
    var self = this;
    if (self.textbox.val().trim() === '') {
      self.onChange(null);
      self.textbox.val('');
      $timeout.cancel(self.editTimerId);
      return;
    }
    $timeout.cancel(self.editTimerId);
    self.editTimerId = $timeout(function() {
      var date = self.textbox.val(),
        isValid = TimezoneService.isValid(date, customDateFormat);

      if (isValid) {
        self.prevDate = parseDate(date, customDateFormat);
        self.onChange(formattedISODate(self.prevDate));
      } else {
        self.textbox.val(customFormattedDate(self.prevDate));
      }
    }, 1000);
  };

  return Datepicker;
};

