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

module.exports = function(TimezoneService, $timeout) {
  var datePattern = /^(0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[012])\/\d{4}$/i,
      parseDate = TimezoneService.parseDate,
      formattedDate = TimezoneService.formattedDate,
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
          div = element.find('div'),
          input = element.find('input'),
          setDate = function(date) {
            div.datepicker('setDate', parseDate(date).toDate());
            div.find('.ui-datepicker-current-day').click();
          };

      scope.change = function(scope) {
        var range = scope.daterange.split(/\s+?-\s+?/i),
            isMatching = range.every(function(date) {
              return datePattern.test(date);
            });

        if(isMatching) {
          range.forEach(function(date) {
            setDate(date);
          });
        }
      };

      div.datepicker({
        onSelect: function(dateText, inst) {
          previous = current;
          current = parseDate(new Date(inst.selectedYear, inst.selectedMonth, inst.selectedDay));
          if(previous == -1 || previous == current) {
            previous = current;
            input.val(formattedDate(current));
          } else {
            var start = minDate(current, previous),
                end = maxDate(current, previous);

            $timeout(function(){
              scope.startDate = formattedISODate(start);
              scope.endDate = formattedISODate(end);

              input.val(formattedDate(start) + ' - ' + 
                        formattedDate(end));
            });
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
