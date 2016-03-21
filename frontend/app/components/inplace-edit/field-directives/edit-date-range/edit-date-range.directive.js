// -- copyright
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
// ++

angular
  .module('openproject.inplace-edit')
  .directive('inplaceEditorDateRange', inplaceEditorDateRange);

function inplaceEditorDateRange($timeout, TimezoneService, WorkPackageFieldService,
    EditableFieldsState, Datepicker, inplaceEditAll, responsiveView, ConfigurationService) {

  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    templateUrl: '/components/inplace-edit/field-directives/edit-date-range/' +
      'edit-date-range.directive.html',

    controller: angular.noop,
    controllerAs: 'customEditorController',

    link: function(scope, element) {
      var field = scope.field;
      var customDateFormat = 'YYYY-MM-DD';

      function getTitle(labelName) {
        return I18n.t('js.inplace.button_edit', {
          attribute: WorkPackageFieldService.getLabel(
            EditableFieldsState.workPackage,
            labelName
          )
        });
      }

      function getDateLabel(labelName) {
        return I18n.t('js.label_date_with_format', {
          date_attribute: WorkPackageFieldService.getLabel(
            EditableFieldsState.workPackage,
            labelName
          ),
          format: customDateFormat
        });
      }

      /**
       * The directive may be used with date pickers in accessibility mode,
       * thus avoid setting it up when it is actually disabled
       */
      function includeDatePicker() {

        startDatepicker = new Datepicker(divStart, inputStart, scope.startDate);
        endDatepicker = new Datepicker(divEnd, inputEnd, scope.endDate);
        startDatepicker.onChange = function(date) {
          scope.startDate = field.value.startDate = date;
          if (startDatepicker.prevDate.isAfter(endDatepicker.prevDate)) {
            scope.startDateIsChanged = true;
            scope.endDate = field.value.dueDate = scope.startDate;
            endDatepicker.setDate(scope.endDate);
          }
        };
        scope.onStartEdit = function() {
          scope.startDateIsChanged = scope.endDateIsChanged = false;
          startDatepicker.onEdit();
        };
        endDatepicker.onChange = function(date) {
          scope.endDate = field.value.dueDate = date;
          if (endDatepicker.prevDate.isBefore(startDatepicker.prevDate)) {
            scope.endDateIsChanged = true;
            scope.startDate = field.value.startDate = scope.endDate;
            startDatepicker.setDate(scope.startDate);
          }
        };
        scope.onEndEdit = function() {
          scope.startDateIsChanged = scope.endDateIsChanged = false;
          endDatepicker.onEdit();
        };

        startDatepicker.onDone = endDatepicker.onDone = function() {
          $timeout(function() {
            form.scope().editPaneController.discardEditing();
          });
        };

        startDatepicker.textbox.on('click focusin', function() {
          if (scope.hideDatePicker) {
            return;
          }

          if (divStart.is(':hidden') || divEnd.is(':visible')) {
            endDatepicker.hide();
            startDatepicker.show();
          }
          scope.startDateIsChanged = scope.endDateIsChanged = false;
        });

        endDatepicker.textbox.on('click focusin', function() {
          if (scope.hideDatePicker) {
            return;
          }

          if (divEnd.is(':hidden') || divStart.is(':visible')) {
            endDatepicker.show();
            startDatepicker.hide();
          }
          scope.startDateIsChanged = scope.endDateIsChanged = false;
        });

        angular.element('#content').on('click', function(e) {
          var target = angular.element(e.target);
          if (!target.is('.inplace-edit--date-range input') &&
            target.parents('.hasDatepicker').length <= 0 &&
            target.parents('.ui-datepicker-header').length <= 0) {
            startDatepicker.hide();
            endDatepicker.hide();
          }
        });

        startDatepicker.setState(!responsiveView.isSmall());
        endDatepicker.setState(!responsiveView.isSmall());

        responsiveView.onResize(function () {
          startDatepicker.setState(!responsiveView.isSmall());
          endDatepicker.setState(!responsiveView.isSmall());
        });

        $timeout(function() {
          inplaceEditAll.state || startDatepicker.focus();
        });
      }


      scope.startDate = field.value.startDate;
      scope.endDate = field.value.dueDate;

      scope.dateFormat = customDateFormat;

      scope.startDateLabel = getDateLabel('startDate');
      scope.endDateLabel = getDateLabel('dueDate');

      scope.startDateTitle = getTitle('startDate');
      scope.endDateTitle = getTitle('dueDate');

      var form = element.parents('.inplace-edit--form'),
        inputStart = element.find('.inplace-edit--date-range-start-date'),
        inputEnd = element.find('.inplace-edit--date-range-end-date'),
        divStart = element.find('.inplace-edit--date-range-start-date-picker'),
        divEnd = element.find('.inplace-edit--date-range-end-date-picker'),
        startDatepicker, endDatepicker;

      scope.startDateIsChanged = scope.endDateIsChanged = false;

      if (scope.endDate) {
        scope.endDate = TimezoneService.formattedISODate(scope.endDate);
      }
      if (scope.startDate) {
        scope.startDate = TimezoneService.formattedISODate(scope.startDate);
      }

      scope.execute = function() {
        form.scope().editPaneController.submit();
      };

      if (ConfigurationService.accessibilityModeEnabled()) {
        scope.onStartEdit = function() {
          field.value.startDate = scope.startDate;
        };

        scope.onEndEdit = function() {
          field.value.dueDate = scope.endDate;
        };

      } else {
        includeDatePicker();
      }

    }
  };
}
