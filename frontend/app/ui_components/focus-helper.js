//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

// TODO move to UI components
module.exports = function ($timeout, FOCUSABLE_SELECTOR) {

  var minimumOffsetForNewSwitchInMs = 100;
  var lastFocusSwitch = -minimumOffsetForNewSwitchInMs;
  var lastPriority = -1;

  function throttleAndCheckIfAllowedFocusChangeBasedOnTimeout() {
    var allowFocusSwitch = (Date.now() - lastFocusSwitch) >= minimumOffsetForNewSwitchInMs;

    // Always update so that a chain of focus-change-requests gets considered as one
    lastFocusSwitch = Date.now();

    return allowFocusSwitch;
  }

  function checkIfAllowedFocusChange(priority) {
    var checkTimeout = throttleAndCheckIfAllowedFocusChangeBasedOnTimeout();

    if (checkTimeout) {
      // new timeout window -> reset priority
      lastPriority = -1;
    } else {
      // within timeout window
      if (priority > lastPriority) {
        lastPriority = priority;
        return true;
      }
    }

    return checkTimeout;
  }

  var FocusHelper = {
    getFocusableElement: function (element) {
      var focusser = element.find('input.ui-select-focusser');

      if (focusser.length > 0) {
        return focusser[0];
      }

      var focusable = element;

      if (!element.is(FOCUSABLE_SELECTOR)) {
        focusable = element.find(FOCUSABLE_SELECTOR);
      }

      return focusable[0];
    },

    focus: function (element) {
      var focusable = angular.element(FocusHelper.getFocusableElement(element)),
        $focusable = angular.element(focusable),
        isDisabled = $focusable.is('[disabled]');

      if (isDisabled && !$focusable.attr('ng-disabled')) {
        $focusable.prop('disabled', false);
      }

      focusable.focus();

      if (isDisabled && !$focusable.attr('ng-disabled')) {
        $focusable.prop('disabled', true);
      }
    },

    focusElement: function (element, priority) {
      if (!checkIfAllowedFocusChange(priority)) {
        return;
      }

      $timeout(function () {
        FocusHelper.focus(element);
      });
    },

    focusUiSelect: function (element) {
      $timeout(function () {
        element.find('.ui-select-match').trigger('click');
      });
    },

    // TODO: remove when select2 is not used
    focusSelect2Element: function (element) {
      var focusSelect2ElementRecursiv = function (retries) {
        $timeout(function () {
          element.select2('focus');

          var isSelect2Focused = angular.element(document.activeElement).hasClass('select2-input');

          if (!isSelect2Focused && retries > 0) {
            focusSelect2ElementRecursiv(--retries);
          }
        });
      };

      focusSelect2ElementRecursiv(3);
    },

  };

  return FocusHelper;
};
