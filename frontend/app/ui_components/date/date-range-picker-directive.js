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
          form = element.parents('.inplace-edit--form'),
          inputStart = element.find('.inplace-edit--date-range-start-date'),
          inputEnd = element.find('.inplace-edit--date-range-end-date'),
          divStart = element.find('.inplace-edit--date-range-start-date-picker'),
          divEnd = element.find('.inplace-edit--date-range-end-date-picker'),
          prevStartDate = '',
          prevEndDate = '',
          addClearButton = function (inp) {
            setTimeout(function() {
              var buttonPane = div.find('.ui-datepicker-buttonpane');

              if(buttonPane.find('.ui-datepicker-clear').length > 0) {
                buttonPane.find('.ui-datepicker-clear').remove();
              }

              angular.element( '<button>', {
                    text: 'Clear',
                    click: function() {
                      setDate(div, inp, null);
                      inp.change();
                      addClearButton(div, inp);
                    }
                })
                .addClass('ui-datepicker-clear ui-state-default ui-priority-primary ui-corner-all')
                .appendTo(buttonPane);
            }, 100);
          },
          setDate = function(div, input, date) {
            if(date) {
              div.datepicker('option', 'defaultDate', formattedDate(date));
              div.datepicker('option', 'setDate', formattedDate(date));
              input.val(customFormattedDate(date));
              input.attr('title', customFormattedDate(date));
            } else {
              div.datepicker('option', 'defaultDate', null);
              div.datepicker('option', 'setDate', null);
              input.val('');
              input.change();
              input.attr('title', noDate);
              date = null;
            }
          };

      scope.execute = function() {
        form.scope().editPaneController.submit(false);
      };

      inputStart.attr({
        'placeholder': customDateFormat,
        'aria-label': customDateFormat,
        'title': noStartDate
      });
      inputEnd.attr({
        'placeholder': customDateFormat,
        'aria-label': customDateFormat,
        'title': noEndDate
      });

      inputStart.on('change', function() {
        if(inputStart.val().trim() === '') {
          $timeout(function() {
            scope.startDate = null;
          });
          inputStart.val('');
          inputStart.attr('title', noStartDate);
          inputEnd.datepicker('option', 'minDate', null);
          $timeout.cancel(startTimerId);
          return;
        }
        $timeout.cancel(startTimerId);
        startTimerId = $timeout(function() {
          var date = inputStart.val(),
              isValid = TimezoneService.isValid(date, customDateFormat);

          if(isValid){
            scope.startDate = formattedISODate(parseDate(date, customDateFormat));
            inputStart.attr('title', customFormattedDate(date));
          }
        }, 1000);
      }).on('click', function() {
        inputStart.datepicker('show');
      });

      inputEnd.on('change', function() {
        if(inputEnd.val().trim() === '') {
          $timeout(function() {
            scope.endDate = null;
          });
          inputEnd.val('');
          inputEnd.attr('title', noEndDate);
          inputStart.datepicker('option', 'maxDate', null);
          $timeout.cancel(endTimerId);
          return;
        }
        $timeout.cancel(endTimerId);
        endTimerId = $timeout(function() {
          var date = inputEnd.val(),
              isValid = TimezoneService.isValid(date, customDateFormat);

          if(isValid){
            scope.endDate = formattedISODate(parseDate(date, customDateFormat));
            inputEnd.attr('title', customFormattedDate(date));
          }
        }, 1000);
      }).on('click', function(){
        inputEnd.datepicker('show');
      });

      divStart.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        changeMonth: true,
        showButtonPanel: true,
        dateFormat: datepickerFormat,
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
        beforeShow: function() {
          addClearButton(inputStart);
        },
        onChangeMonthYear: function() {
          addClearButton(inputStart);
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
        }
      });
      divEnd.datepicker({
        firstDay: ConfigurationService.startOfWeek(),
        showWeeks: true,
        changeMonth: true,
        dateFormat: datepickerFormat,
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
        beforeShow: function() {
          addClearButton(inputEnd);
        },
        onChangeMonthYear: function() {
          addClearButton(inputEnd);
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
      $timeout(function() {
        inputStart.click();
      });

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

      angular.element('.work-packages--details-content').on('click', function(e) {
        var target = angular.element(e.target);
        if(!target.is('.inplace-edit--date-range input') && 
            target.parents('.inplace-edit--date-range .hasDatepicker').length <= 0) {
          divStart.hide();
          divEnd.hide();
        }
      });
    }
  };
};
