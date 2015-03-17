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

module.exports = function(TimezoneService, ConfigurationService, I18n, $timeout) {
  var parseDate = TimezoneService.parseDate,
      formattedDate = function(date) {
        return TimezoneService.parseDate(date).format('L');
      },
      formattedISODate = TimezoneService.formattedISODate;

  return {
    restrict: 'EA',
    replace: true,
    scope: { 
      date: '=',
      noDateText: '='
    },
    templateUrl: '/templates/components/inplace_editor/date/date_picker.html',
    link: function(scope, element) {
      var selectedDate,
          timerId,
          div = element.find('div'),
          input = element.find('input'),
          setDate = function(date) {
            if(date) {
              div.datepicker('setDate', parseDate(date).toDate());
              div.find('.ui-datepicker-current-day').click();
            } else {
              div.datepicker('setDate', null);
              scope.editableDate = scope.noDateText;
              scope.date = null;
            }
          },
          addClearButton = function (inp) {
            setTimeout(function() {
              if(div.find('.ui-datepicker-clear').length > 0) {
                return;
              }

              var buttonPane = jQuery(inp)
                  .find(".ui-datepicker-buttonpane");

              jQuery( "<button>", {
                  text: "Clear",
                  click: function() {
                    setDate(null);
                  }
              })
              .appendTo(buttonPane)
              .addClass("ui-datepicker-clear ui-state-default ui-priority-primary ui-corner-all");
            }, 1);
          };

      scope.change = function(scope) {
        $timeout.cancel(timerId);
          timerId = $timeout(function() {
          var isMatching = TimezoneService.isValid(scope.date);;

          if(isMatching) {
            setDate(scope.date);
          }
        }, 500);
      };

      scope.click = function(scope) {
        div.toggle();
      };

      div.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        showButtonPanel: true,
        beforeShow: function(inp) {
          addClearButton(inp);
        },
        onChangeMonthYear: function(year, month, inst) {
          addClearButton(inst.input);
        },
        onSelect: function(dateText, inst) {
          selectedDate = parseDate(new Date(inst.selectedYear, inst.selectedMonth, inst.selectedDay));
          $timeout(function() {
            scope.date = formattedISODate(selectedDate);
          });

          scope.editableDate = formattedDate(selectedDate);
        }
      });
      setDate(scope.date);
      div.toggle();
    }
  };
};

(function ($) {
  $.extend($.datepicker, {

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
    }
  });
}(jQuery));