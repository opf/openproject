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
jQuery(function($) {
  var regions = $.datepicker.regional;
  var regional = regions[I18n.locale] || regions[''];

  // see ./app/helpers/application_helper.rb:508
  if (typeof I18n.firstDayOfWeek === 'number') {
    regional.firstDay = I18n.firstDayOfWeek;
  }

  $.datepicker.setDefaults(regional);

  var gotoToday = $.datepicker._gotoToday;

  $.datepicker._gotoToday = function (id) {
    gotoToday.call(this, id);
    var target = $(id),
      inst = this._getInst(target[0]),
      dateStr = $.datepicker._formatDate(inst);
    target.val(dateStr);
    target.blur();
    $.datepicker._hideDatepicker();
  };

  var defaults = {
    showWeek: true,
    changeMonth: true,
    changeYear: true,
    yearRange: 'c-100:c+10',
    dateFormat: 'yy-mm-dd',
    showButtonPanel: true,
    calculateWeek: function (day) {
      var dayOfWeek = new Date(+day);

      if (day.getDay() != 1) {
        dayOfWeek.setDate(day.getDate() - day.getDay() + 1);
      }

      return $.datepicker.iso8601Week(dayOfWeek);
    }
  };

  $.datepicker.setDefaults(defaults);

  $.extend($.datepicker, {

    _originalGotoToday: $.datepicker._gotoToday,
    _gotoToday: function(id) {
      var target = $(id),
          inst = this._getInst(target[0]),
          today = new Date(),
          date = this._formatDate(inst, today.getDate(), today.getMonth(), today.getFullYear());
      this._originalGotoToday(id);
      this._selectDate(id, date);
    },

    // Reference the orignal function so we can override it and call it later
    _inlineDatepicker2: $.datepicker._inlineDatepicker,

    // Override the _inlineDatepicker method
    _inlineDatepicker: function (target, inst) {

      // Call the original
      this._inlineDatepicker2(target, inst);

      var beforeShow = $.datepicker._get(inst, 'beforeShow');

      if (beforeShow) {
        beforeShow.apply(target, [target, inst]);
      }
    },
    _checkOffsetOriginal: $.datepicker._checkOffset,

    _checkOffset: function(inst, offset, isFixed) {
      var _offset = $.datepicker._checkOffsetOriginal(inst, offset, isFixed);
      var alterOffset = this._get(inst, 'alterOffset');
      if (alterOffset) {
        var inp = inst.input ? inst.input[0] : null;
        // trigger custom callback
        return alterOffset.apply(inp, [_offset]);
      }
      return _offset;
    }
  });
});
