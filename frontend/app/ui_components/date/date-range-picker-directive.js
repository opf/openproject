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
                          I18n, $timeout) {
  var parseDate = TimezoneService.parseDate,
      formattedDate = function(date) {
        return TimezoneService.parseDate(date).format('L');
      },
      formattedISODate = TimezoneService.formattedISODate,
      noStartDate = I18n.t('js.label_no_start_date'),
      noEndDate = I18n.t('js.label_no_due_date');
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
          inputStart = element.find('input.start'),
          inputEnd = element.find('input.end'),
          prevStartDate = '',
          prevEndDate = '',
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
          setDate = function(input, date) {
            if(date) {
              input.datepicker('option', 'defaultDate', formattedDate(date));
              input.datepicker('option', 'setDate', formattedDate(date));
              input.val(formattedDate(date));
            } else {
              input.datepicker('option', 'defaultDate', null);
              input.datepicker('option', 'setDate', null);
              input.val('');
              date = null;
            }
          };

      inputStart.attr('placeholder', noStartDate);
      inputEnd.attr('placeholder', noEndDate);

      inputStart.on('change', function() {
        if(inputStart.val().replace(/^\s+|\s+$/g, '') === '') {
          $timeout(function() {
            scope.startDate = null;
          });
          inputStart.val('');
          $timeout.cancel(startTimerId);  
          return;
        }
        $timeout.cancel(startTimerId);
        startTimerId = $timeout(function() {
          var date = inputStart.val(),
              isValid = TimezoneService.isValid(date, 'DD/MM/YYYY');

          if(isValid){
            scope.startDate = formattedISODate(date);
          }
        }, 1000);
      });

      inputEnd.on('change', function() {
        if(inputEnd.val().replace(/^\s+|\s+$/g, '') === '') {
          $timeout(function() {
            scope.endDate = null;
          });
          inputEnd.val('');
          $timeout.cancel(endTimerId);  
          return;
        }
        $timeout.cancel(startTimerId);
        startTimerId = $timeout(function() {
          var date = inputEnd.val(),
              isValid = TimezoneService.isValid(date, 'DD/MM/YYYY');

          if(isValid){
            scope.endDate = formattedISODate(date);
          }
        }, 1000);
      });

      inputStart.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        changeMonth: true,
        numberOfMonths: 2,
        showButtonPanel: true,
        dateFormat: 'dd/mm/yy',
        inline: true,
        alterOffset: function(offset) {
          var wHeight = jQuery(window).height(),
              dpHeight = jQuery('#ui-datepicker-div').height(),
              inputTop = inputStart.offset().top,
              inputHeight = inputStart.innerHeight();

          if((inputTop + inputHeight + dpHeight) > wHeight) {
            offset.top -= inputHeight - 4;
          }
          return offset;
        },
        beforeShow: function() {
          addClearButton(inputStart);
        },
        onChangeMonthYear: function() {
          addClearButton(inputStart);
        },
        onClose: function(selectedDate) {
          if(!selectedDate || selectedDate === '' || selectedDate === prevStartDate) {
            return;
          }
          var parsedDate = parseDate(selectedDate, 'DD/MM/YYYY');
          prevStartDate = parsedDate;
          $timeout(function() {
            scope.startDate = formattedISODate(parsedDate);
          });
          inputEnd.datepicker('option', 'minDate', selectedDate ? selectedDate : null);
        }
      });
      inputEnd.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        changeMonth: true,
        numberOfMonths: 2,
        dateFormat: 'dd/mm/yy',
        inline: true,
        alterOffset: function(offset) {
          var wHeight = jQuery(window).height(),
              dpHeight = jQuery('#ui-datepicker-div').height(),
              inputTop = inputEnd.offset().top,
              inputHeight = inputEnd.innerHeight();

          if((inputTop + inputHeight + dpHeight) > wHeight) {
            offset.top -= inputHeight - 4;
          }
          return offset;
        },
        beforeShow: function() {
          addClearButton(inputEnd);
        },
        onChangeMonthYear: function() {
          addClearButton(inputEnd);
        },
        onClose: function(selectedDate) {
          if(!selectedDate || selectedDate === '' || selectedDate === prevEndDate) {
            return;
          }
          var parsedDate = parseDate(selectedDate, 'DD/MM/YYYY');
          prevEndDate = parsedDate;
          $timeout(function() {
            scope.endDate = formattedISODate(parsedDate);
          });
          inputStart.datepicker('option', 'maxDate', selectedDate ? selectedDate : null);
        }
      });
      if(scope.endDate) {
        prevEndDate = formattedDate(scope.endDate);
        inputStart.datepicker('option', 'maxDate', formattedDate(scope.endDate));
      }
      if(scope.startDate) {
        prevStartDate = formattedDate(scope.startDate);
        inputEnd.datepicker('option', 'minDate', formattedDate(scope.startDate));
      }

      setDate(inputStart, scope.startDate);
      setDate(inputEnd, scope.endDate);
    }
  };
};