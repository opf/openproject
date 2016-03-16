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

interface opDatePickerScope extends ng.IScope {
  onDeactivate:Function,
  onChange:Function
}

function opDatePickerLink(scope: opDatePickerScope, element: ng.IAugmentedJQuery, attrs, ngModel) {
  // we don't want the date picker in the accessibility mode
  if (this.ConfigurationService.accessibilityModeEnabled()) {
    return;
  }

  let input = element.find('.hidden-date-picker-input');
  let datePickerContainer = element.find('.ui-datepicker--container');
  let datePickerInstance;
  let DatePicker = this.Datepicker;
  let onDeactivate = scope.onDeactivate;
  let onChange = scope.onChange;
  let onClickCallback;

  let unbindNgModelInitializationWatch = scope.$watch(() => ngModel.$viewValue !== NaN, () => {
    showDatePicker();
    unbindNgModelInitializationWatch();
  });

  function hide() {
    datePickerInstance.hide();
    unregisterClickCallback();
  };

  function registerClickCallback() {
    // HACK: we need to bind to 'mousedown' because the wp-edit-field.directive
    // binds to 'click' and stops the event propagation
    onClickCallback = angular.element('body').bind('mousedown', function(e) {
      let target = angular.element(e.target);
      let parentSelector = '.ui-datepicker-header, .' + datePickerContainer.attr('class').split(' ').join('.')
      if(!target.is(input) &&
        target.parents(parentSelector).length <= 0) {

        hide();
        onDeactivate();
      }
    });
  }

  function unregisterClickCallback() {
    angular.element('body').unbind('mousedown', onClickCallback);
  }

  function showDatePicker() {
    datePickerInstance = new DatePicker(datePickerContainer, input, ngModel.$viewValue);
    ensureDatePickerVisible();

    datePickerInstance.onChange = function(date) {
      ngModel.$setViewValue(date);
      onChange();
    };

    datePickerInstance.onDone = function() {
      onChange();
    };

    registerClickCallback();
  };

  function ensureDatePickerVisible() {
    let visibilityContainer = datePickerContainer.offsetParent();
    let templateContainer = element.children('div');
    // typescript compiler does not like it if we simply use
    // containerBoundaries = visibilityContainer.offset()
    let containerBoundaries = { top: visibilityContainer.offset().top,
                                left: visibilityContainer.offset().left,
                                right: visibilityContainer.offset().left + visibilityContainer.width(),
                                bottom: visibilityContainer.offset().top + visibilityContainer.height() };

    let positions = [
      {
        check: ((templateContainer.offset().top + templateContainer.height() + datePickerContainer.height() <= containerBoundaries.bottom) &&
               (templateContainer.offset().left + datePickerContainer.width() <= containerBoundaries.right)),
        css: {} //no change
      },
      {
        check: ((templateContainer.offset().top + templateContainer.height() + datePickerContainer.height() <= containerBoundaries.bottom) &&
               (templateContainer.offset().left + datePickerContainer.width() >= containerBoundaries.right)),
        css: { marginLeft: templateContainer[0].offsetWidth - datePickerContainer.width() }
      },
      {
        check: ((templateContainer.offset().top - datePickerContainer.height() >= containerBoundaries.top) &&
               (templateContainer.offset().left + datePickerContainer.width() <= containerBoundaries.right)),
        css: { marginTop: -templateContainer[0].offsetHeight - datePickerContainer.height() + 'px' }
      },
      {
        check: ((templateContainer.offset().top - datePickerContainer.height() >= containerBoundaries.top) &&
               (templateContainer.offset().left + datePickerContainer.width() >= containerBoundaries.right)),
        css: { marginTop: -templateContainer[0].offsetHeight - datePickerContainer.height() + 'px',
               marginLeft: templateContainer[0].offsetWidth - datePickerContainer.width() }
      },
      {
        check: templateContainer.offset().left + templateContainer.width() + datePickerContainer.width() <= containerBoundaries.right,
        css: { marginTop: -templateContainer[0].offsetHeight/2 - datePickerContainer.height()/2 + 'px',
               marginLeft: templateContainer[0].offsetWidth }
      },
      {
        check: true,
        css: { marginTop: -templateContainer[0].offsetHeight/2 - datePickerContainer.height()/2 + 'px',
               marginLeft: -datePickerContainer[0].offsetWidth }
      }
    ]

    // use _.some to limit the checks to the first truthy position
    _.some(positions, (position) => {
      if (position.check) {
        datePickerContainer.css(position.css);
        return true;
      }
    });
  };
}

function opDatePicker(ConfigurationService, Datepicker) {
  let dependencies = { ConfigurationService: ConfigurationService,
                       Datepicker: Datepicker };

  return {
    restrict: 'E',
    transclude: true,
    templateUrl: '/components/wp-edit/op-date-picker.directive.html',
    //  by curtesy of http://stackoverflow.com/a/33614939/3206935
    link: angular.bind(dependencies, opDatePickerLink),
    require: 'ngModel',
    scope: {
      onChange: "&",
      onDeactivate: "&"
    }
  };
}

angular
  .module('openproject')
  .directive('opDatePicker', opDatePicker);
