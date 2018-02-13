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
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';
import {CollectionResource} from '../../api/api-v3/hal-resources/collection-resource.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageTableRefreshService} from '../../wp-table/wp-table-refresh-request.service';

class WpStatusContextMenuController {
  public status:CollectionResource[] = [];

  constructor(protected $timeout:ng.ITimeoutService,
              protected $scope:any,
              protected wpEditing:WorkPackageEditingService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected wpTableRefresh:WorkPackageTableRefreshService) {
    const wp = $scope.workPackage;
    var changeset = wpEditing.changesetFor(wp);
    $scope.$ctrl = this;

    changeset.getForm().then((form:any) => {
      this.status = form.schema.status.allowedValues;

      this.$timeout(() => {
        // Reposition again now that status are loaded
        this.$scope.$root.$emit('repositionDropdown');
      })
    });

    this.$scope.updateStatus = function (status:any) {
      changeset.setValue('status', status);
      if(!wp.isNew) {
        changeset.save().then(() => {
          wpNotificationsService.showSave(wp);
          wpTableRefresh.request('Altered work package status via button');
        });
      }
    };
  }
}

function wpStatusContextMenuService(ngContextMenu:any) {
  return ngContextMenu({
    templateUrl: '/components/context-menus/wp-status-context-menu/wp-status-context-menu.service.html',
    controller: WpStatusContextMenuController
  });
}

opWorkPackagesModule.factory('WpStatusContextMenu', wpStatusContextMenuService);
