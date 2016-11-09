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

/**
 * The search input of ui-select fields doesn't get the focus when the
 * field gets activated.
 * This is a known issue and has not been solved yet (11.10.2016)
 * Usage: add directive to <ui-select ...> element.
 **/

import {wpDirectivesModule} from '../../../angular-modules';

function uiSelectFocusFix( $timeout ) {
  return {
    restrict: 'A',
    require: 'uiSelect',
    link: function(scope, element, attrs, $select) {

      element.on('keyup', keyEvent => {
        if (keyEvent.keyCode === 27 && $select.open) {
          keyEvent.preventDefault();
          keyEvent.stopPropagation();
          $select.close();
        }
      });

      scope.$watch(() => $select.open, isOpen => {
        if ( isOpen ) {
          $timeout( () => { $select.focusSearchInput(); } );
        }
      });

    }
  };
}

wpDirectivesModule.directive('uiSelectFocusFix', uiSelectFocusFix);

