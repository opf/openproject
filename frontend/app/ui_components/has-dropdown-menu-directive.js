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

module.exports = function($rootScope, $injector, $window, $parse, FocusHelper) {

  function getCssPositionProperties(dropdown, trigger) {
    var hOffset = 0,
      vOffset = 0;
    if (dropdown.hasClass('dropdown-anchor-top')) {
      vOffset = - dropdown.outerHeight() - trigger.outerHeight() + parseInt(trigger.css('margin-top'), 10);
    }

    // Styling logic taken from jQuery-dropdown plugin: https://github.com/plapier/jquery-dropdown
    // (dual MIT/GPL-Licensed)

    // Position the dropdown relative-to-parent or relative-to-document
    if (dropdown.hasClass('dropdown-relative')) {
      return {
        left: dropdown.hasClass('dropdown-anchor-right') ?
          trigger.position().left -
          (dropdown.outerWidth(true) - trigger.outerWidth(true)) -
          parseInt(trigger.css('margin-right'), 10) + hOffset :
          trigger.position().left + parseInt(trigger.css('margin-left'), 10) + hOffset,
        top: trigger.position().top +
          trigger.outerHeight(true) -
          parseInt(trigger.css('margin-top'), 10) + vOffset
      };
    } else {
      return {
        left: dropdown.hasClass('dropdown-anchor-right') ?
          trigger.offset().left - (dropdown.outerWidth() - trigger.outerWidth()) + hOffset : trigger.offset().left + hOffset,
        top: trigger.offset().top + trigger.outerHeight() + vOffset
      };
    }
  }

  function getPositionPropertiesOfEvent(event) {
    var position = { };

    if (event.pageX && event.pageY) {
      position.top = Math.max(event.pageY, 0);
      position.left = Math.max(event.pageX, 0);
    } else {
      var bounding = angular.element(event.target)[0].getBoundingClientRect();

      position.top = Math.max(bounding.bottom, 0);
      position.left = Math.max(bounding.left, 0);
    }

    return position;
  }

  function getCssPositionPropertiesOfEvent(event) {
    var position = getPositionPropertiesOfEvent(event);

    position.top += 'px';
    position.left += 'px';

    return position;
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
        pointerPosition,
        pointerCssPosition,
        win = angular.element($window),
        menuElement,
        afterFocusOn = attrs.afterFocusOn,
        positionRelativeTo = attrs.positionRelativeTo,
        triggerOnEvent = (attrs.triggerOnEvent || 'click') + '.dropdown.openproject';

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
        var ignoreFocusOpener = true;
        pointerPosition = getPositionPropertiesOfEvent(event);
        pointerCssPosition = getCssPositionPropertiesOfEvent(event);
        $rootScope.$broadcast('openproject.dropdown.closeDropdowns', ignoreFocusOpener);
        // prepare locals, these define properties to be passed on to the context menu scope
        var localKeys = (attrs.locals || '').split(',').map(function(local) {
          return local.trim();
        });
        angular.forEach(localKeys, function(key) {
          locals[key] = scope[key];
        });

        ctrl.open();

        contextMenu.open(element, locals)
          .then(function(element) {
            menuElement = element;
            menuElement.trap();
            positionDropdown();
            menuElement.on('click', function(e) {
              // allow inputs to be clickable
              // without closing the dropdown
              if (angular.element(e.target).is(':input')) {
                e.stopPropagation();
              }
            });
          });
      }

      function close(ignoreFocusOpener) {
        ctrl.close();
        var disableFocus = ignoreFocusOpener;
        contextMenu.close(disableFocus).then(function() {
          if (!ignoreFocusOpener) {
            FocusHelper.focusElement(afterFocusOn ? element.find(afterFocusOn) : element);
          }
        });
      }

      function positionDropdown() {
        var positionRelativeToElement = positionRelativeTo ?
          element.find(positionRelativeTo) : element;
        if (attrs.triggerOnEvent == 'contextmenu') {
          menuElement.css(pointerCssPosition);
          adjustPosition(menuElement, pointerPosition);
        } else {
          menuElement.css(getCssPositionProperties(menuElement, positionRelativeToElement));
        }
      }

      function adjustPosition($element, pointerPosition) {
        var viewport = {
          top : win.scrollTop(),
          left : win.scrollLeft()
        };

        viewport.right = viewport.left + win.width();
        viewport.bottom = viewport.top + win.height();
        var bounds = $element.offset();
        bounds.right = bounds.left + $element.outerWidth();
        bounds.bottom = bounds.top + $element.outerHeight();
        if (viewport.right < bounds.right) {
          $element.css('left', pointerPosition.left - $element.outerWidth());
        }
        if (viewport.bottom < bounds.bottom) {
          $element.css('top', pointerPosition.top - $element.outerHeight());
        }
      }

      element.bind(triggerOnEvent, function(event) {
        event.preventDefault();
        event.stopPropagation();
        scope.$apply(function() {
          toggle(event);
        });

        // set css position parameters after the digest has been completed
        if (contextMenu.active()) positionDropdown();
      });

      scope.$on('openproject.dropdown.closeDropdowns', function(event, ignoreFocusOpener) {
        if (!ctrl.opened()) {
          return;
        }
        close(ignoreFocusOpener);
      });

      scope.$on('openproject.dropdown.reposition', function() {
        if (contextMenu.active() && menuElement && ctrl.opened()) {
          positionDropdown();
        }
      });

      var elementKeyUpString = 'keyup.contextmenu.dropdown.openproject';
      element
        .off(elementKeyUpString)
        .on(elementKeyUpString, function(event) {
        // Alt + Shift + F10
        if (event.keyCode === 121 && event.shiftKey && event.altKey) {
          if (!contextMenu.active()) {
            open(event);
          }
        }
      });


      // We need the off/on stuff in order to not have a new listener
      // for every linking. It's not only not efficient, if causes bugs
      // because of closures
      // we also add an event namespace to avoid off'ing unrelated listeners
      // We can leave it like this
      // or move to the compile function of the directive
      // or move to a service and make sure it's called only once

      var repositioningEventString = 'resize.dropdown.openproject, mousewheel.dropdown.openproject';
      win
        .off(repositioningEventString)
        .on(repositioningEventString, function() {
          $rootScope.$broadcast('openproject.dropdown.reposition');
        });

      var keyUpEventString = 'keyup.dropdown.openproject';
      win
        .off(keyUpEventString).on(keyUpEventString, function(event) {
        if (event.keyCode === 27) {
          $rootScope.$broadcast('openproject.dropdown.closeDropdowns');
        }
      });

      function handleWindowClickEvent() {
        $rootScope.$broadcast('openproject.dropdown.closeDropdowns');
      }

      // Firefox treats a right-click as a click and a contextmenu event while other browsers
      // just treat it as a contextmenu event
      var clickEventString = 'click.dropdown.openproject';
      win
        .off(clickEventString)
        .on(clickEventString, handleWindowClickEvent);
      win
        .off(triggerOnEvent)
        .on(triggerOnEvent, handleWindowClickEvent);
    }
  };
};
