angular.module('openproject.uiComponents')

.directive('hasDropdownMenu', [
  '$injector',
  '$window',
  '$parse',
  function($injector, $window, $parse) {

  function getCssPositionProperties(dropdown, trigger) {
    var hOffset = 0,
      vOffset = 0;

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

      // prepare locals, these define properties to be passed on to the context menu scope
      var localKeys = attrs.locals.split(',').map(function(local) {
        return local.trim();
      });
      angular.forEach(localKeys, function(key) {
        locals[key] = scope[key];
      });

      function toggle(event) {
        active() ? close() : open(event);
      }

      function active() {
        return contextMenu.active() && ctrl.opened();
      }

      function open(event) {
        ctrl.open();

        contextMenu.open(event.target, locals)
          .then(function(element) {
            menuElement = element;
            angular.element(element).trap();
          });
      }

      function close() {
        ctrl.close();

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
}]);
