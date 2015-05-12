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
                          EditableFieldsState, Datepicker) {
  var parseISODate = TimezoneService.parseISODate,
      customDateFormat = 'YYYY-MM-DD',
      customFormattedDate = function(date) {
        return parseISODate(date).format(customDateFormat);
      },
      getLabel = WorkPackageFieldService.getLabel.bind(null, EditableFieldsState.workPackage),
      getTitle = function(labelName) {
        return I18n.t('js.inplace.button_edit', {
          attribute: getLabel(labelName)
        });
      };
  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    scope: {},
    require: '^workPackageField',
    templateUrl: '/templates/work_packages/inplace_editor/custom/editable/daterange.html',
    controller: function() {
    },
    controllerAs: 'customEditorController',
    link: function(scope, element, attrs, fieldController) {
      scope.startDate = fieldController.writeValue.startDate;
      scope.endDate = fieldController.writeValue.dueDate;
      var form = element.parents('.inplace-edit--form'),
          inputStart = element.find('.inplace-edit--date-range-start-date'),
          inputEnd = element.find('.inplace-edit--date-range-end-date'),
          divStart = element.find('.inplace-edit--date-range-start-date-picker'),
          divEnd = element.find('.inplace-edit--date-range-end-date-picker'),
          startDatepicker, endDatepicker;

      scope.startDateIsChanged = scope.endDateIsChanged = false;

      if (scope.endDate) {
        scope.endDate = customFormattedDate(scope.endDate);
      }
      if (scope.startDate) {
        scope.startDate = customFormattedDate(scope.startDate);
      }

      scope.execute = function() {
        form.scope().editPaneController.submit(false);
      };

      startDatepicker = new Datepicker(divStart, inputStart, scope.startDate);
      endDatepicker = new Datepicker(divEnd, inputEnd, scope.endDate);
      startDatepicker.onChange = function(date) {
        scope.startDate = fieldController.writeValue.startDate = date;
        if (startDatepicker.prevDate.isAfter(endDatepicker.prevDate)) {
          scope.startDateIsChanged = true;
          scope.endDate = fieldController.writeValue.dueDate = scope.startDate;
          endDatepicker.setDate(scope.endDate);
        }
      };
      scope.onStartEdit = function() {
        scope.startDateIsChanged = scope.endDateIsChanged = false;
        startDatepicker.onEdit();
      };
      endDatepicker.onChange = function(date) {
        scope.endDate = fieldController.writeValue.dueDate = date;
        if (endDatepicker.prevDate.isBefore(startDatepicker.prevDate)) {
          scope.endDateIsChanged = true;
          scope.startDate = fieldController.writeValue.startDate = scope.endDate;
          startDatepicker.setDate(scope.startDate);
        }
      };
      scope.onEndEdit = function() {
        scope.startDateIsChanged = scope.endDateIsChanged = false;
        endDatepicker.onEdit();
      };

      startDatepicker.onDone = endDatepicker.onDone = function() {
        form.scope().editPaneController.discardEditing();
      };

      $timeout(function() {
        startDatepicker.focus();
      });

      startDatepicker.textbox.on('click focusin', function() {
        if (divStart.is(':hidden') || divEnd.is(':visible')) {
          endDatepicker.hide();
          startDatepicker.show();
        }
        scope.startDateIsChanged = scope.endDateIsChanged = false;
      }).attr({
        'placeholder': customDateFormat,
        'aria-label': customDateFormat,
        'title': getTitle('startDate')
      });

      endDatepicker.textbox.on('click focusin', function() {
        if (divEnd.is(':hidden') || divStart.is(':visible')) {
          endDatepicker.show();
          startDatepicker.hide();
        }
        scope.startDateIsChanged = scope.endDateIsChanged = false;
      }).attr({
        'placeholder': customDateFormat,
        'aria-label': customDateFormat,
        'title': getTitle('dueDate')
      });

      angular.element('.work-packages--details-content').on('click', function(e) {
        var target = angular.element(e.target);
        if (!target.is('.inplace-edit--date-range input') &&
          target.parents('.hasDatepicker').length <= 0 &&
          target.parents('.ui-datepicker-header').length <= 0) {
          startDatepicker.hide();
          endDatepicker.hide();
        }
      });
    }
  };
};
