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

import {openprojectModule} from '../../../angular-modules';

interface GroupEditInPlaceScope {
  cancelEdition:Function,
  editing:boolean,
  enterEditingMode:Function,
  keyDown:Function,
  leaveEditingMode:Function,
  // The current name:
  name:string|null,
  // The name before this edition. Important in case user changes several times
  // before submitting the form:
  nameBefore:string|null,
  // The orginal value in case user cancels edition.
  nameOriginal:string|null,
  onvaluechange:Function,
  saveEdition:Function
}

function groupEditInPlace($timeout:any, $parse:any) {
  return {
    restrict: 'E',
    templateUrl: '/components/types/form-configuration/group-edit-in-place.directive.html',
    scope: {
      onvaluechange: '='
    },
    link: function(scope:GroupEditInPlaceScope, element:any, attributes:any) {
      scope.editing = false;
      scope.name         = attributes.name || '';
      // The name before last change;
      scope.nameOriginal = attributes.name || '';
      scope.enterEditingMode = function() {
        scope.editing = true;
        scope.nameBefore = scope.name;
        $timeout(function(){
          angular.element('input', element).trigger('focus');
        }, 100);
      };

      scope.leaveEditingMode = function() {
        scope.editing = false;
      };

      scope.cancelEdition = function() {
        scope.name = scope.nameBefore;
        scope.leaveEditingMode();
      };

      scope.saveEdition = function() {
        let newValue:string = angular.element("input", element[0]).first().val();
        scope.nameOriginal = scope.name;
        scope.name = newValue;
        scope.leaveEditingMode();
        if (attributes.onvaluechange) {
          scope.onvaluechange(attributes.key, newValue);
        }
      };

      scope.keyDown = function($event:KeyboardEvent) {
        if ($event.keyCode == 27) {
          // ESC
          scope.cancelEdition();
        }
        if ($event.keyCode == 13) {
          // ENTER
          // a blur event will trigger `saveEdition`
          angular.element('input', element[0]).blur();
          // Do not submit the whole form:
          $event.preventDefault();
          $event.stopPropagation();
        }
        // Prevent submitting the form
        return false;
      };
    }
  };
};

openprojectModule.directive('groupEditInPlace', groupEditInPlace);
