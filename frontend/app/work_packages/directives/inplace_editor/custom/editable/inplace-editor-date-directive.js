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

module.exports = function(WorkPackageFieldService, EditableFieldsState, 
                          TimezoneService, ConfigurationService, I18n, 
                          $timeout) {
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
      };
  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    scope: {},
    require: '^workPackageField',
    templateUrl: '/templates/work_packages/inplace_editor/custom/editable/date.html',
    controller: function() {
    },
    controllerAs: 'customEditorController',
    link: function(scope, element, attrs, fieldController) {
      scope.fieldController = fieldController;
      var timerId = 0,
          prevDate = '',
          form = element.parents('.inplace-edit--form'),
          input = element.find('.inplace-edit--date'),
          datepickerContainer = element.find('.inplace-edit--date-picker'),
          setDate = function(div, inp, date) {
            if(date) {
              div.datepicker('option', 'defaultDate', formattedDate(date));
              div.datepicker('option', 'setDate', formattedDate(date));
              inp.val(customFormattedDate(date));
            } else {
              div.datepicker('option', 'defaultDate', null);
              div.datepicker('option', 'setDate', null);
              inp.val('');
              inp.change();
              date = null;
            }
          };

      scope.execute = function() {
        form.scope().editPaneController.submit(false);
      };

      input.attr({
        'placeholder': '-',
        'aria-label': customDateFormat
      });

      input.on('change', function() {
        if(input.val().trim() === '') {
          $timeout(function() {
            scope.fieldController.writeValue = null;
          });
          input.val('');
          $timeout.cancel(timerId);
          return;
        }
        $timeout.cancel(timerId);
        timerId = $timeout(function() {
          var date = input.val(),
              isValid = TimezoneService.isValid(date, customDateFormat);

          if(isValid){
            scope.fieldController.writeValue = formattedISODate(parseDate(date, customDateFormat));
          }
        }, 1000);
      }).on('click', function() {
        datepickerContainer.show();
      });

      datepickerContainer.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        changeMonth: true,
        numberOfMonths: 1,
        dateFormat: datepickerFormat,
        alterOffset: function(offset) {
          var wHeight = angular.element(window).height(),
              dpHeight = angular.element('#ui-datepicker-div').height(),
              inputTop = input.offset().top,
              inputHeight = input.innerHeight();

          if((inputTop + inputHeight + dpHeight) > wHeight) {
            offset.top -= inputHeight - 4;
          }
          return offset;
        },
        onSelect: function(selectedDate) {
          if(!selectedDate || selectedDate === '' || selectedDate === prevDate) {
            return;
          }
          prevDate = parseDate(selectedDate, customDateFormat);
          $timeout(function() {
            scope.fieldController.writeValue = formattedISODate(prevDate);
          });
          input.focus();
          datepickerContainer.hide();
        }
      });

      if(scope.fieldController.writeValue) {
        prevDate = formattedDate(scope.fieldController.writeValue);
      }

      setDate(datepickerContainer, input, scope.fieldController.writeValue);

      $timeout(function() {
        input.click().focus();
      });

      angular.element('.work-packages--details-content').on('click', function(e) {
        var target = angular.element(e.target);
        if(!target.is('.inplace-edit--date input') && 
            target.parents('.inplace-edit--date .hasDatepicker').length <= 0 &&
            target.parents('.ui-datepicker-header').length <= 0) {
          datepickerContainer.hide();
        }
      });
    }
  };
};
