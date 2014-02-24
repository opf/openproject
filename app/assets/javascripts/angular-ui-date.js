/*global angular */
/*
 jQuery UI Datepicker plugin wrapper

 @note If ≤ IE8 make sure you have a polyfill for Date.toISOString()
 @param [ui-date] {object} Options to pass to $.fn.datepicker() merged onto uiDateConfig
 */

angular.module('ui.date', [])

.constant('uiDateConfig', {})

.directive('uiDate', ['uiDateConfig', '$timeout', function (uiDateConfig, $timeout) {
  'use strict';
  var options;
  options = {};
  angular.extend(options, uiDateConfig);
  return {
    require:'?ngModel',
    link:function (scope, element, attrs, controller) {
      var getOptions = function () {
        return angular.extend({}, uiDateConfig, scope.$eval(attrs.uiDate));
      };
      var initDateWidget = function () {
        var opts = getOptions();

        // If we have a controller (i.e. ngModelController) then wire it up
        if (controller) {
          // Override ngModelController's $setViewValue
          // so that we can ensure that a Date object is being pass down the $parsers
          // This is to handle the case where the user types directly into the input box
          var _$setViewValue = controller.$setViewValue;
          var settingValue = false;
          controller.$setViewValue = function () {
            if ( !settingValue ) {
              settingValue = true;
              element.datepicker("setDate", element.datepicker("getDate"));
              _$setViewValue.call(controller, element.datepicker("getDate"));
              $timeout(function() {settingValue = false;});
            }
          };

          // Set the view value in a $apply block when users selects
          // (calling directive user's function too if provided)
          var _onSelect = opts.onSelect || angular.noop;
          opts.onSelect = function (value, picker) {
            scope.$apply(function() {
              controller.$setViewValue(value);
              _onSelect(value, picker);
              element.blur();
            });
          };

          // Don't show if we are already setting the value in $setViewValue()
          // (calling directive user's function too if provided)
          var _beforeShow = opts.beforeShow || angular.noop;
          opts.beforeShow = function(input, inst) {
            return !settingValue && _beforeShow(input, inst);
          };

          // Update the date picker when the model changes
          controller.$render = function () {
            var date = controller.$viewValue;
            if ( angular.isDefined(date) && date !== null && !angular.isDate(date) ) {
              throw new Error('ng-Model value must be a Date object - currently it is a ' + typeof date + ' - use ui-date-format to convert it from a string');
            }
            element.datepicker("setDate", date);
          };
        }
        // If we don't destroy the old one it doesn't update properly when the config changes
        element.datepicker('destroy');
        // Create the new datepicker widget
        element.datepicker(opts);
        if ( controller ) {
          // Force a render to override whatever is in the input text box
          controller.$render();
        }
      };
      // Watch for changes to the directives options
      scope.$watch(getOptions, initDateWidget, true);
    }
  };
}
])

.constant('uiDateFormatConfig', '')

.directive('uiDateFormat', ['uiDateFormatConfig', function(uiDateFormatConfig) {
  var directive = {
    require:'ngModel',
    link: function(scope, element, attrs, modelCtrl) {
      var dateFormat = attrs.uiDateFormat || uiDateFormatConfig;
      if ( dateFormat ) {
        // Use the datepicker with the attribute value as the dateFormat string to convert to and from a string
        modelCtrl.$formatters.push(function(value) {
          if (angular.isString(value) ) {
            return jQuery.datepicker.parseDate(dateFormat, value);
          }
          return null;
        });
        modelCtrl.$parsers.push(function(value){
          if (value) {
            return jQuery.datepicker.formatDate(dateFormat, value);
          }
          return null;
        });
      } else {
        // Default to ISO formatting
        modelCtrl.$formatters.push(function(value) {
          if (angular.isString(value) ) {
            return new Date(value);
          }
          return null;
        });
        modelCtrl.$parsers.push(function(value){
          if (value) {
            return value.toISOString();
          }
          return null;
        });
      }
    }
  };
  return directive;
}]);
