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
                          $timeout, Datepicker) {
  var parseISODate = TimezoneService.parseISODate,
      customDateFormat = 'YYYY-MM-DD',
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
      var form = element.parents('.inplace-edit--form'),
          input = element.find('.inplace-edit--date'),
          datepickerContainer = element.find('.inplace-edit--date-picker'),
          datepicker;

      scope.execute = function() {
        form.scope().editPaneController.submit(false);
      };

      if(scope.fieldController.writeValue) {
        scope.fieldController.writeValue = customFormattedDate(scope.fieldController.writeValue);
      }

      datepicker = new Datepicker(datepickerContainer, input, scope.fieldController.writeValue);
      datepicker.onChange = function(date) {
        scope.fieldController.writeValue = date;
      };
      scope.onEdit = function() {
        datepicker.onEdit();
      };
      datepicker.onDone = function() {
        form.scope().editPaneController.discardEditing();
      };

      datepicker.textbox.attr({
        'placeholder': '-',
        'aria-label': customDateFormat
      });

      scope.showDatepicker = function() {
        datepicker.show();
      };

      $timeout(function() {
        datepicker.focus();
      });

      angular.element('.work-packages--details-content').on('click', function(e) {
        var target = angular.element(e.target);
        if(!target.is('.inplace-edit--date input') && 
            target.parents('.inplace-edit--date .hasDatepicker').length <= 0 &&
            target.parents('.ui-datepicker-header').length <= 0) {
          datepicker.hide();
        }
      });
    }
  };
};
