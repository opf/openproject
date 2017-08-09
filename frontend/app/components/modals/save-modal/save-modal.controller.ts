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

import {wpControllersModule} from '../../../angular-modules';
import {WorkPackagesListService} from '../../wp-list/wp-list.service';
import {States} from '../../states.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service';
import {QueryDmService} from '../../api/api-v3/hal-resource-dms/query-dm.service';

function SaveModalController(this:any,
                             $scope:any,
                             saveModal:any,
                             states:States,
                             wpListService:WorkPackagesListService,
                             wpNotificationsService:WorkPackageNotificationService,
                             $q:ng.IQService,
                             NotificationsService:any) {
  this.name = 'Save';
  this.closeMe = saveModal.deactivate;

  $scope.isStarred = false;
  $scope.isPublic = false;

  $scope.setValues = (isStarred:boolean, isPublic:boolean) => {
    $scope.isStarred = isStarred;
    $scope.isPublic = isPublic;
  }

  $scope.saveQueryAs = (name:string) => {
    const query = states.query.resource.value!;
    query.public = $scope.isPublic;

    wpListService
      .create(query, name)
      .then((savedQuery:QueryResource) => {
        if ($scope.isStarred && !savedQuery.starred) {
          return wpListService.toggleStarred(savedQuery).then(() => saveModal.deactivate())
        }

        saveModal.deactivate();
        return $q.when(true);
      })
      .catch((error:any) => wpNotificationsService.handleErrorResponse(error));
  };
}

wpControllersModule.controller('SaveModalController', SaveModalController);
