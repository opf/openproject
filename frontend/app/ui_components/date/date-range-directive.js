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
  var datePattern = /^(0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[012])\/\d{4}$/i,
      parseDate = TimezoneService.parseDate,
      formattedDate = function(date) {
        return TimezoneService.parseDate(date).format('L');
      },
      formattedISODate = TimezoneService.formattedISODate;

  return {
    restrict: 'EA',
    replace: true,
    scope: { 
      startDate: '=', 
      endDate: '=' 
    },
    template: '<div class="daterange"><input ng-model="daterange" ng-change="change(this)" /><div></div></div>',
    link: function(scope, element) {
      var previous,
          current,
          timerId,
          div = element.find('div'),
          input = element.find('input'),
          setDate = function(date) {
            if(date) {
              div.datepicker('setDate', parseDate(date).toDate());
              div.find('.ui-datepicker-current-day').click();
            }
          },
          clearDate = function(inst) {
            previous = current = null;
            var onSelect = jQuery.datepicker._get(inst, "onSelect");
            if (onSelect) {
              onSelect.apply(input, inst);  // trigger custom callback
            }
          },
          addClearButton = function (inp, inst) {
            setTimeout(function() {
              var buttonPane = jQuery(inp)
                  .find(".ui-datepicker-buttonpane");

              jQuery( "<button>", {
                  text: "Clear",
                  click: function() {
                    clearDate(inst);
                  }
              })
              .appendTo(buttonPane)
              .addClass("ui-datepicker-clear ui-state-default ui-priority-primary ui-corner-all");
            }, 1);
          };

      scope.change = function(scope) {
        $timeout.cancel(timerId);
        timerId = $timeout(function() {
          var range = scope.daterange.split(/\s+?-\s+?/i),
              isMatching = range.every(function(date) {
                return TimezoneService.isValid(date);
              });

          if(isMatching) {
            range.forEach(function(date) {
              setDate(date);
            });
          }
        }, 500);
      };

      div.datepicker({
        minDate: null,
        maxDate: null,
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        onSelect: function(dateText, inst) {
          if(!inst) {
            input.val('No start date set - No end date set');
            $timeout(function() {
              scope.startDate = scope.endDate = null;
            });
          } else {
            previous = current;
            current = parseDate(new Date(inst.selectedYear, inst.selectedMonth, inst.selectedDay));
            if(!previous || previous.isSame(current)) {
              previous = current;
              $timeout(function() {
                scope.startDate = formattedISODate(previous);
                scope.endDate = null;
              });

              input.val(formattedDate(previous));
            } else {
              var start = minDate(current, previous),
                  end = maxDate(current, previous);

              $timeout(function(){
                scope.startDate = formattedISODate(start);
                scope.endDate = formattedISODate(end);

                input.val(formattedDate(start) + ' - ' + formattedDate(end));
              });
            }
          }
        },
        beforeShowDay: function(selectedDay) {
          var isSelected = parseDate(selectedDay) >= minDate(current, previous) && 
                           parseDate(selectedDay) <= maxDate(current, previous);
          return [true, isSelected ? 'date-range-selected' : ''];
        }
      });

      setDate(scope.startDate);
      setDate(scope.endDate);
    }
  };

  function minDate(firstDate, secondDate) {
    if(secondDate && firstDate && firstDate.isAfter(secondDate)) {
      return secondDate;
    }

    return firstDate;
  }

  function maxDate(firstDate, secondDate) {
    if(secondDate && firstDate && !firstDate.isAfter(secondDate)) {
      return secondDate;
    }

    return firstDate;
  }
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