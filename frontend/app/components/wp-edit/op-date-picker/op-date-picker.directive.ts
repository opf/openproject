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
  onChange?:Function;
  onClose?:Function;
}

function opDatePickerLink(this:any, scope:OpDatePickerScope, element:ng.IAugmentedJQuery, _attrs:any) {
  // we don't want the date picker in the accessibility mode
  if (this.ConfigurationService.accessibilityModeEnabled()) {
    return;
  }

  let input = element.find('input');
  let datePickerInstance:any;
  let DatePicker = this.Datepicker;

  let defaultHandler = function () {
    input.change();
  };
  let onChange = scope.onChange || defaultHandler;
  let onClose = scope.onClose || defaultHandler;

  input.focus( () => {
    showDatePicker();
  });

  input.keydown((event) => {
    if (input.val() === '') {
      datePickerInstance.clear();
    }
  });

  function showDatePicker() {
    let options = {
      onSelect: (date:any) => {
        datePickerInstance.hide();

        let val = date;

        if (input.val().trim() === '') {
          val = null;
        }
        input.val(val);
        onChange();
      },
      onClose: onClose
    };
    datePickerInstance = new DatePicker(input, input.val(), options);

    datePickerInstance.show();
  }
}

function opDatePicker(ConfigurationService:any, Datepicker:any) {
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
    scope: {
      onChange: '&?',
      onClose: '&?',
    }
  };
}

angular
  .module('openproject')
  .directive('opDatePicker', opDatePicker);
