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
  return {
    restrict: 'EA',
    replace: true,
    scope: { 
      startDate: '=', 
      endDate: '=' 
    },
    template: '<div class="daterange"><input /><div></div></div>',
    link: function(scope, element) {
      var previous = -1,
          current = -1,
          div = element.find('div'),
          input = element.find('input');

      div.datepicker({
        onSelect: function(dateText, inst) {
          previous = +current;
          current = inst.selectedDay;
          if(previous == -1 || previous == current) {
            previous = current;
            input.val(dateText);
          } else {
            var start = new Date(inst.selectedYear, inst.selectedMonth, Math.min(previous,current)),
                end = new Date(inst.selectedYear, inst.selectedMonth, Math.max(previous,current));
            $timeout(function(){
              scope.startDate = TimezoneService.formattedISODate(start);
              scope.endDate = TimezoneService.formattedISODate(end);

              input.val(TimezoneService.formattedDate(start) + ' - ' + 
                        TimezoneService.formattedDate(end));
            });
          }
        },
        beforeShowDay: function(selectedDay) {
          var isSelected = selectedDay.getDate() >= Math.min(previous, current) && 
                           selectedDay.getDate() <= Math.max(previous, current);
          return [true, (isSelected ? 'date-range-selected' : '')];
        }
      })
      .position({
        my: 'left top',
        at: 'left bottom',
        of: '.daterange input'
      });

      div.datepicker('setDate', TimezoneService.parseDate(scope.startDate).toDate());
      div.find('.ui-datepicker-current-day').click();

      div.datepicker('setDate', TimezoneService.parseDate(scope.endDate).toDate());
      div.find('.ui-datepicker-current-day').click();
    }
  };
};
