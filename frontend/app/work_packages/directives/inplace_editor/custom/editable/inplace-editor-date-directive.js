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
      formattedDate = function(date) {
        return TimezoneService.parseDate(date).format('L');
      },
      formattedISODate = TimezoneService.formattedISODate;
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
          input = element,
          addClearButton = function (inp) {
            setTimeout(function() {
              var buttonPane = jQuery('.ui-datepicker-buttonpane');

              if(buttonPane.find('.ui-datepicker-clear').length === 0) {
                buttonPane.find('.ui-datepicker-clear').remove();
              }

              jQuery( '<button>', {
                    text: 'Clear',
                    click: function() {
                      inp.val('');
                      inp.change();
                    }
                })
                .addClass('ui-datepicker-clear ui-state-default ui-priority-primary ui-corner-all')
                .appendTo(buttonPane);
            }, 1);
          },
          setDate = function(inp, date) {
            if(date) {
              inp.datepicker('option', 'defaultDate', formattedDate(date));
              inp.datepicker('option', 'setDate', formattedDate(date));
              inp.val(formattedDate(date));
            } else {
              inp.datepicker('option', 'defaultDate', null);
              inp.datepicker('option', 'setDate', null);
              inp.val('');
              date = null;
            }
          };

      input.attr('placeholder', '');

      input.on('change', function() {
        if(input.val().replace(/^\s+|\s+$/g, '') === '') {
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
              isValid = TimezoneService.isValid(date, 'DD/MM/YYYY');

          if(isValid){
            scope.fieldController.writeValue = formattedISODate(date);
          }
        }, 1000);
      });

      input.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        changeMonth: true,
        numberOfMonths: 1,
        dateFormat: 'dd/mm/yy',
        alterOffset: function(offset) {
          var wHeight = jQuery(window).height(),
              dpHeight = jQuery('#ui-datepicker-div').height(),
              inputTop = input.offset().top,
              inputHeight = input.innerHeight();

          if((inputTop + inputHeight + dpHeight) > wHeight) {
            offset.top -= inputHeight - 4;
          }
          return offset;
        },
        beforeShow: function() {
          addClearButton(input);
        },
        onChangeMonthYear: function() {
          addClearButton(input);
        },
        onClose: function(selectedDate) {
          if(!selectedDate || selectedDate === '' || selectedDate === prevDate) {
            return;
          }
          var parsedDate = parseDate(selectedDate, 'DD/MM/YYYY');
          prevDate = parsedDate;
          $timeout(function() {
            scope.fieldController.writeValue = formattedISODate(parsedDate);
          });
        }
      });

      if(scope.fieldController.writeValue) {
        prevDate = formattedDate(scope.fieldController.writeValue);
      }

      setDate(input, scope.fieldController.writeValue);

      angular.element('.work-packages--details-content').scroll(function() {
        input.datepicker('hide');
        angular.element('#ui-datepicker-div').blur();
      });

      angular.element(window).resize(function() {
        input.datepicker('hide');
        angular.element('#ui-datepicker-div').blur();
      });
    }
  };
};
