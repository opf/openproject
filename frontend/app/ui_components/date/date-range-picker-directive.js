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

module.exports = function(TimezoneService, ConfigurationService,
                          I18n, $timeout, WorkPackageFieldService,
                          EditableFieldsState) {
  var parseDate = TimezoneService.parseDate,
      parseISODate = TimezoneService.parseISODate,
      formattedDate = function(date) {
        return TimezoneService.parseDate(date).format('L');
      },
      formattedISODate = TimezoneService.formattedISODate,
      customDateFormat = 'YYYY-MM-DD',
      datepickerFormat = 'yy-mm-dd',
      customFormattedDate = function(date) {
        return parseISODate(date).format(customDateFormat);
      },
      getLabel = WorkPackageFieldService.getLabel.bind(null, EditableFieldsState.workPackage),
      getTitle = function(labelName) {
        return I18n.t('js.inplace.button_edit', {attribute: getLabel(labelName)});
      };
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      'startDate': '=',
      'endDate': '='
    },
    templateUrl: '/templates/components/inplace_editor/date/date_range_picker.html',
    link: function(scope, element) {
      var startTimerId = 0,
          endTimerId = 0,
          form = element.parents('.inplace-edit--form'),
          inputStart = element.find('.inplace-edit--date-range-start-date'),
          inputEnd = element.find('.inplace-edit--date-range-end-date'),
          divStart = element.find('.inplace-edit--date-range-start-date-picker'),
          divEnd = element.find('.inplace-edit--date-range-end-date-picker'),
          prevStartDate = '',
          prevEndDate = '',
          setDate = function(div, input, date) {
            if(date) {
              div.datepicker('option', 'defaultDate', customFormattedDate(date));
              div.datepicker('option', 'setDate', customFormattedDate(date));
              input.val(customFormattedDate(date));
            } else {
              div.datepicker('option', 'defaultDate', null);
              div.datepicker('option', 'setDate', null);
              input.val('');
              input.change();
              date = null;
            }
          };

      scope.execute = function() {
        form.scope().editPaneController.submit(false);
      };

      inputStart.attr({
        'placeholder': customDateFormat,
        'aria-label': customDateFormat,
        'title': getTitle('startDate')
      });
      inputEnd.attr({
        'placeholder': customDateFormat,
        'aria-label': customDateFormat,
        'title': getTitle('dueDate')
      });

      inputStart.on('change', function() {
        if(inputStart.val().trim() === '') {
          $timeout(function() {
            scope.startDate = null;
          });
          inputStart.val('');
          divEnd.datepicker('option', 'minDate', null);
          $timeout.cancel(startTimerId);
          return;
        }
        $timeout.cancel(startTimerId);
        startTimerId = $timeout(function() {
          var date = inputStart.val(),
              isValid = TimezoneService.isValid(date, customDateFormat);

          if(isValid){
            scope.startDate = formattedISODate(parseDate(date, customDateFormat));
          }
        }, 1000);
      });

      inputEnd.on('change', function() {
        if(inputEnd.val().trim() === '') {
          $timeout(function() {
            scope.endDate = null;
          });
          inputEnd.val('');
          divStart.datepicker('option', 'maxDate', null);
          $timeout.cancel(endTimerId);
          return;
        }
        $timeout.cancel(endTimerId);
        endTimerId = $timeout(function() {
          var date = inputEnd.val(),
              isValid = TimezoneService.isValid(date, customDateFormat);

          if(isValid){
            scope.endDate = formattedISODate(parseDate(date, customDateFormat));
          }
        }, 1000);
      });

      divStart.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        changeMonth: true,
        dateFormat: datepickerFormat,
        defaultDate: customFormattedDate(scope.startDate),
        inline: true,
        alterOffset: function(offset) {
          var wHeight = angular.element(window).height(),
              dpHeight = angular.element('#ui-datepicker-div').height(),
              inputTop = divStart.offset().top,
              inputHeight = divStart.innerHeight();

          if((inputTop + inputHeight + dpHeight) > wHeight) {
            offset.top -= inputHeight - 4;
          }
          return offset;
        },
        onSelect: function(selectedDate) {
          if(!selectedDate || selectedDate === '' || selectedDate === prevStartDate) {
            return;
          }
          prevStartDate = parseDate(selectedDate, customDateFormat);
          $timeout(function() {
            scope.startDate = formattedISODate(prevStartDate);
          });
          divEnd.datepicker('option', 'minDate', selectedDate ? selectedDate : null);
          divStart.hide();
          inputStart.focus();
        }
      });
      divEnd.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        changeMonth: true,
        dateFormat: datepickerFormat,
        defaultDate: customFormattedDate(scope.endDate),
        inline: true,
        alterOffset: function(offset) {
          var wHeight = angular.element(window).height(),
              dpHeight = angular.element('#ui-datepicker-div').height(),
              inputTop = divEnd.offset().top,
              inputHeight = divEnd.innerHeight();

          if((inputTop + inputHeight + dpHeight) > wHeight) {
            offset.top -= inputHeight - 4;
          }
          return offset;
        },
        onSelect: function(selectedDate) {
          if(!selectedDate || selectedDate === '' || selectedDate === prevEndDate) {
            return;
          }
          prevEndDate = parseDate(selectedDate, customDateFormat);
          $timeout(function() {
            scope.endDate = formattedISODate(prevEndDate);
          });
          divStart.datepicker('option', 'maxDate', selectedDate ? selectedDate : null);
          divEnd.hide();
          inputEnd.focus();
        }
      });

      if(scope.endDate) {
        prevEndDate = formattedDate(scope.endDate);
        divStart.datepicker('option', 'maxDate', customFormattedDate(scope.endDate));
      }
      if(scope.startDate) {
        prevStartDate = formattedDate(scope.startDate);
        divEnd.datepicker('option', 'minDate', customFormattedDate(scope.startDate));
      }

      setDate(divStart, inputStart, scope.startDate);
      setDate(divEnd, inputEnd, scope.endDate);
      $timeout(function() {
        inputStart.click().focus();
      });

      inputStart.on('click focusin', function() {
        if(divStart.is(':hidden') || divEnd.is(':visible')) {
          divEnd.hide();
          divStart.show();
        }
      });

      inputEnd.on('click focusin', function() {
        if(divEnd.is(':hidden') || divStart.is(':visible')) {
          divEnd.show();
          divStart.hide();
        }
      });

      angular.element('.work-packages--details-content').on('click', function(e) {
        var target = angular.element(e.target);
        if(!target.is('.inplace-edit--date-range input') && 
            target.parents('.hasDatepicker').length <= 0 &&
            target.parents('.ui-corner-all').length <= 0) {
          divStart.hide();
          divEnd.hide();
        }
      });
    }
  };
};
