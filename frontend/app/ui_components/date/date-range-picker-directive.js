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
          inputStart = element.find('.inplace-edit--date-range-start-date'),
          inputEnd = element.find('.inplace-edit--date-range-end-date'),
          divStart = element.find('.inplace-edit--date-range-start-date-picker'),
          divEnd = element.find('.inplace-edit--date-range-end-date-picker'),
          prevStartDate = '',
          prevEndDate = '',
          addClearButton = function (div, inp) {
            setTimeout(function() {
              var buttonPane = div.find('.ui-datepicker-buttonpane');

              if(buttonPane.find('.ui-datepicker-clear').length === 0) {
                buttonPane.find('.ui-datepicker-clear').remove();
              }

              jQuery( '<button>', {
                    text: 'Clear',
                    click: function() {
                      setDate(div, inp, null);
                    }
                })
                .addClass('ui-datepicker-clear ui-state-default ui-priority-primary ui-corner-all')
                .appendTo(buttonPane);
            }, 1);
          },
          setDate = function(div, input, date) {
            if(date) {
              div.datepicker('option', 'defaultDate', formattedDate(date));
              div.datepicker('option', 'setDate', formattedDate(date));
              input.val(formattedDate(date));
            } else {
              div.datepicker('option', 'defaultDate', null);
              div.datepicker('option', 'setDate', null);
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

      divStart.datepicker({
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
              inputTop = divStart.offset().top,
              inputHeight = divStart.innerHeight();

          if((inputTop + inputHeight + dpHeight) > wHeight) {
            offset.top -= inputHeight - 4;
          }
          return offset;
        },
        beforeShow: function() {
          addClearButton(divStart, inputStart);
        },
        onChangeMonthYear: function() {
          addClearButton(divStart, inputStart);
        },
        onSelect: function(selectedDate) {
          if(!selectedDate || selectedDate === '' || selectedDate === prevStartDate) {
            return;
          }
          var parsedDate = parseDate(selectedDate, 'DD/MM/YYYY');
          prevStartDate = parsedDate;
          $timeout(function() {
            scope.startDate = formattedISODate(parsedDate);
          });
          divEnd.datepicker('option', 'minDate', selectedDate ? selectedDate : null);
          divStart.hide();
        }
      });
      divEnd.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        changeMonth: true,
        numberOfMonths: 2,
        dateFormat: 'dd/mm/yy',
        inline: true,
        alterOffset: function(offset) {
          var wHeight = jQuery(window).height(),
              dpHeight = jQuery('#ui-datepicker-div').height(),
              inputTop = divEnd.offset().top,
              inputHeight = divEnd.innerHeight();

          if((inputTop + inputHeight + dpHeight) > wHeight) {
            offset.top -= inputHeight - 4;
          }
          return offset;
        },
        beforeShow: function() {
          addClearButton(divEnd, inputEnd);
        },
        onChangeMonthYear: function() {
          addClearButton(divEnd, inputEnd);
        },
        onSelect: function(selectedDate) {
          if(!selectedDate || selectedDate === '' || selectedDate === prevEndDate) {
            return;
          }
          var parsedDate = parseDate(selectedDate, 'DD/MM/YYYY');
          prevEndDate = parsedDate;
          $timeout(function() {
            scope.endDate = formattedISODate(parsedDate);
          });
          divStart.datepicker('option', 'maxDate', selectedDate ? selectedDate : null);
          divEnd.hide();
        }
      });

      if(scope.endDate) {
        prevEndDate = formattedDate(scope.endDate);
        divStart.datepicker('option', 'maxDate', formattedDate(scope.endDate));
      }
      if(scope.startDate) {
        prevStartDate = formattedDate(scope.startDate);
        divEnd.datepicker('option', 'minDate', formattedDate(scope.startDate));
      }

      setDate(divStart, inputStart, scope.startDate);
      setDate(divEnd, inputEnd, scope.endDate);

      inputStart.on('click', function() {
        if(divStart.is(':hidden') || divEnd.is(':visible')) {
          divEnd.hide();
          divStart.show();
        }
      });

      inputEnd.on('click', function() {
        if(divEnd.is(':hidden') || divStart.is(':visible')) {
          divEnd.show();
          divStart.hide();
        }
      });

      jQuery('.work-packages--details-content').on('click', function(e) {
        if(!jQuery(e.target).is('.inplace-edit--date-range input') && 
            jQuery(e.target).parents('.inplace-edit--date-range .hasDatepicker').length <= 0) {
          divStart.hide();
          divEnd.hide();
        }
      });
    }
  };
};
