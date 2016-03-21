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
  .directive('inplaceEditorDate', inplaceEditorDate);

function inplaceEditorDate($timeout, inplaceEditAll, TimezoneService,
  Datepicker, responsiveView, ConfigurationService) {
  var parseISODate = TimezoneService.parseISODate,
    customDateFormat = 'YYYY-MM-DD',
    customFormattedDate = function(date) {
      return parseISODate(date).format(customDateFormat);
    };

  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    require: '^wpField',
    templateUrl: '/components/inplace-edit/field-directives/edit-date/' +
      'edit-date.directive.html',

    controller: angular.noop,
    controllerAs: 'customEditorController',

    link: function(scope, element) {
      var field = scope.field;
      
      var form = element.parents('.inplace-edit--form'),
        input = element.find('.inplace-edit--date'),
        datepickerContainer = element.find('.inplace-edit--date-picker'),
        datepicker;

      /**
       * The directive may be used with date pickers in accessibility mode,
       * thus avoid setting it up when it is actually disabled
       */
      function includeDatePicker() {
        datepicker = new Datepicker(datepickerContainer, input, field.value);
        datepicker.onChange = function(date) {
          field.value = date;
        };
        scope.onEdit = function() {
          datepicker.onEdit();
        };
        datepicker.onDone = function() {
          form.scope().editPaneController.discardEditing();
        };

        scope.showDatepicker = function() {
          datepicker.show();
        };

        $timeout(function() {
          inplaceEditAll.state || datepicker.focus();
        });

        angular.element('#content').on('click', function(e) {
          var target = angular.element(e.target);
          if(!target.is('.inplace-edit--date input') &&
            target.parents('.inplace-edit--date .hasDatepicker').length <= 0 &&
            target.parents('.ui-datepicker-header').length <= 0) {
            datepicker.hide();
          }
        });

        datepicker.setState(!responsiveView.isSmall());
        responsiveView.onResize(function () {
          datepicker.setState(!responsiveView.isSmall());
        });
      }

      scope.execute = function() {
        form.scope().editPaneController.submit();
      };

      field.value = field.value && customFormattedDate(field.value);
      scope.dateLabel = I18n.t('js.label_date_with_format', {
        date_attribute: field.getLabel(),
        format: customDateFormat
      });

      if (!ConfigurationService.accessibilityModeEnabled()) {
        includeDatePicker();
      }
    }
  };
}
