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

module.exports = function($injector, $window, $parse, FocusHelper) {

  function getCssPositionProperties(dropdown, trigger) {
    var hOffset = 0,
      vOffset = 0;
    if (dropdown.hasClass('dropdown-anchor-top')) {
      vOffset = - dropdown.outerHeight() - trigger.outerHeight() + parseInt(trigger.css('margin-top'));
    }

    // Styling logic taken from jQuery-dropdown plugin: https://github.com/plapier/jquery-dropdown
    // (dual MIT/GPL-Licensed)

    // Position the dropdown relative-to-parent or relative-to-document
    if (dropdown.hasClass('dropdown-relative')) {
      return {
        left: dropdown.hasClass('dropdown-anchor-right') ?
          trigger.position().left - (dropdown.outerWidth(true) - trigger.outerWidth(true)) - parseInt(trigger.css('margin-right')) + hOffset :
          trigger.position().left + parseInt(trigger.css('margin-left')) + hOffset,
        top: trigger.position().top + trigger.outerHeight(true) - parseInt(trigger.css('margin-top')) + vOffset
      };
    } else {
      return {
        left: dropdown.hasClass('dropdown-anchor-right') ?
          trigger.offset().left - (dropdown.outerWidth() - trigger.outerWidth()) + hOffset : trigger.offset().left + hOffset,
        top: trigger.offset().top + trigger.outerHeight() + vOffset
      };
    }
  }

  return {
    restrict: 'A',
    controller: [function() {
      var dropDownMenuOpened = false;

      this.open = function() {
        dropDownMenuOpened = true;
      };
      this.close = function() {
        dropDownMenuOpened = false;
      };
      this.opened = function() {
        return dropDownMenuOpened;
      };
    }],
    link: function(scope, element, attrs, ctrl) {
      var contextMenu = $injector.get(attrs.target),
        locals = {},
        win = angular.element($window),
        menuElement,
        positionRelativeTo = attrs.positionRelativeTo,
        triggerOnEvent = attrs.triggerOnEvent || 'click';

      /* contextMenu      is a mandatory attribute and used to bind a specific context
                          menu to the trigger event
         triggerOnEvent   allows for binding the event for opening the menu to "click" */


      function toggle(event) {
        active() ? close() : open(event);
      }

      function active() {
        return contextMenu.active() && ctrl.opened();
      }

      function open(event) {
        // prepare locals, these define properties to be passed on to the context menu scope
        var localKeys = (attrs.locals || "").split(',').map(function(local) {
          return local.trim();
        });
        angular.forEach(localKeys, function(key) {
          locals[key] = scope[key];
        });

        ctrl.open();

        contextMenu.open(event.target, locals)
          .then(function(element) {
            menuElement = element;
            angular.element(element).trap();
            menuElement.on('click', function(e) {
              // allow inputs to be clickable
              // without closing the dropdown
              if (angular.element(e.target).is(':input')) {
                e.stopPropagation();
              }
            });
          });
      }

      function close() {
        ctrl.close();
        if (element.is('th')) {
          element.focus();
        } else {
          FocusHelper.focusElement(element);
        }

        contextMenu.close();
      }

      function positionDropdown() {
        var positionRelativeToElement = positionRelativeTo ?
          element.find(positionRelativeTo) : element;

        menuElement.css(getCssPositionProperties(menuElement, positionRelativeToElement));
      }

      element.bind(triggerOnEvent, function(event) {
        event.preventDefault();
        event.stopPropagation();

        scope.$apply(function() {
          toggle(event);
        });

        // set css position parameters after the digest has been completed
        if (contextMenu.active()) positionDropdown();

        scope.$root.$broadcast('openproject.markDropdownsAsClosed', element);
      });

      scope.$on('openproject.markDropdownsAsClosed', function(event, target) {
        if (element !== target && ctrl.opened()) {
          scope.$apply(ctrl.close);
        }
      });

      win.on('resize', function(event) {
        if (contextMenu.active() && menuElement && ctrl.opened()) {
          positionDropdown();
        }
      });

      win.bind('keyup', function(event) {
        if (contextMenu.active() && event.keyCode === 27) {
          scope.$apply(function() {
            close();
          });
        }
      });

      function handleWindowClickEvent(event) {
        if (contextMenu.active() && event.button !== 2) {
          scope.$apply(function() {
            close();
          });
        }
      }

      // Firefox treats a right-click as a click and a contextmenu event while other browsers
      // just treat it as a contextmenu event
      win.bind('click', handleWindowClickEvent);
      win.bind(triggerOnEvent, handleWindowClickEvent);
    }
  };
};
