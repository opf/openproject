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

interface OpDatePickerScope extends ng.IScope {
  onChange:Function;
}

function opDatePickerLink(scope:OpDatePickerScope, element:ng.IAugmentedJQuery, attrs, ngModel) {
  // we don't want the date picker in the accessibility mode
  if (this.ConfigurationService.accessibilityModeEnabled()) {
    return;
  }

  let input = element.find('input');
  let datePickerInstance;
  let DatePicker = this.Datepicker;
  let onChange = scope.onChange;

  let unbindNgModelInitializationWatch = scope.$watch(() => ngModel.$viewValue !== NaN, () => {
    // This indirection is needed to prevent
    // 'Missing instance data for this datepicker' errors.
    input.focus( () => {
      showDatePicker();
    });
    unbindNgModelInitializationWatch();
  });

  input.keydown((event) => {
    if (input.val() === '') {
      datePickerInstance.clear();
    }
  });

  function showDatePicker() {
    let options = { onSelect: (date) => {
        datePickerInstance.hide();

        let val = date;

        if (input.val().trim() === '') {
          val = null;
        }
        ngModel.$setViewValue(val);
        onChange();
      }
    };
    datePickerInstance = new DatePicker(input, ngModel.$viewValue, options);

    datePickerInstance.show();
  }
}

function opDatePicker(ConfigurationService, Datepicker) {
  var dependencies = {
    ConfigurationService: ConfigurationService,
    Datepicker: Datepicker
  };

  return {
    restrict: 'E',
    transclude: true,
    templateUrl: '/components/wp-edit/op-date-picker/op-date-picker.directive.html',
    // http://stackoverflow.com/a/33614939/3206935
    link: angular.bind(dependencies, opDatePickerLink),
    require: 'ngModel',
    scope: {
      onChange: '&',
    }
  };
}

angular
  .module('openproject')
  .directive('opDatePicker', opDatePicker);
