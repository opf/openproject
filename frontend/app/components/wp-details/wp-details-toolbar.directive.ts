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
import {WorkPackageMoreMenuService} from '../work-packages/work-package-more-menu.service';

import {openprojectModule} from '../../angular-modules';
import {WorkPackageEditingService} from '../wp-edit-form/work-package-editing-service';
function wpDetailsToolbar(
  I18n:op.I18n,
  wpEditing:WorkPackageEditingService,
  wpMoreMenuService:WorkPackageMoreMenuService) {

  return {
    restrict: 'E',
    templateUrl: '/components/wp-details/wp-details-toolbar.directive.html',
    scope: {
      workPackage: '='
    },

    link: function(scope:any, attr:ng.IAttributes, element:ng.IAugmentedJQuery) {

      let wpMoreMenu = new (wpMoreMenuService as any)(scope.workPackage);

      wpMoreMenu.initialize().then(() => {
        scope.permittedActions = wpMoreMenu.permittedActions;
        scope.actionsAvailable = wpMoreMenu.actionsAvailable;
      });

      scope.triggerMoreMenuAction = wpMoreMenu.triggerMoreMenuAction.bind(wpMoreMenu);

      scope.displayWatchButton = scope.workPackage.hasOwnProperty('unwatch') ||
        scope.workPackage.hasOwnProperty('watch');

      scope.I18n = I18n;
    }
  };
}

openprojectModule.directive('wpDetailsToolbar', wpDetailsToolbar);
