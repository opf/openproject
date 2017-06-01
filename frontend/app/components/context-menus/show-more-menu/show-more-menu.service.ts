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

import {opWorkPackagesModule} from '../../../angular-modules';

function showMoreMenuService(ngContextMenu:any) {
  return ngContextMenu({
    template: `
      <div class="dropdown dropdown-relative dropdown-anchor-right dropdownToolbar">
        <ul class="dropdown-menu" ng-if="actionsAvailable">
          <li ng-repeat="(action, properties) in permittedActions"
              class="{{action}}">
            <!-- The hrefs with empty URLs are necessary for IE10 to focus these links
            properly. Thus, don't remove the hrefs or the empty URLs! -->
            <a href="" focus="{{ !$index }}"
               ng-click="triggerMoreMenuAction(action, properties.link)">
               <op-icon icon-classes="icon-context {{ properties.css.join(' ') }}"></op-icon>
               {{ I18n.t('js.button_' + action) }}
            </a>
          </li>
        </ul>
      </div>
    `,

    container: '#action-show-more-dropdown-menu'
  });
}

opWorkPackagesModule.factory('ShowMoreDropdownMenu', showMoreMenuService);
