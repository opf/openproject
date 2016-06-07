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

import {RelationsHandler} from "../relations-handler/relations-handler.service";
import {opViewModelsModule} from "../../../angular-modules";
import {HalResource} from "../../api/api-v3/hal-resources/hal-resource.service";

var $state:ng.ui.IStateService;
var WorkPackageService:any;
var ApiNotificationsService:any;

export class ChildRelationsHandler extends RelationsHandler {
  public type:string = 'child';

  public canAddRelation():boolean {
    return !!this.workPackage.addChild;
  }

  public canDeleteRelation() {
    return !!this.workPackage.update;
  }

  public addRelation() {
    var params = {parent_id: this.workPackage.id, projectPath: this.workPackage.project.identifier};

    if ($state.includes('work-packages.show')) {
      $state.go('work-packages.new', params);
    }
    else {
      $state.go('work-packages.list.new', params);
    }
  }

  public getRelatedWorkPackage(relation:HalResource) {
    return relation.$load();
  }

  public removeRelation(scope) {
    var index = this.relations.indexOf(scope.relation);
    var params = {
      lockVersion: scope.relation.lockVersion,
      parentId: null
    };

    WorkPackageService.updateWithPayload(scope.relation, params)
      .then(response => {
        scope.workPackage.lockVersion = response.lockVersion;

        this.relations.splice(index, 1);
        scope.updateFocus(index);
        scope.$emit('workPackageRefreshRequired');
      })
      .catch(error => {
        ApiNotificationsService.addError(error);
      });
  }
}

function childRelationsHandlerService(_$state_, _WorkPackageService_, _ApiNotificationsService_) {
  $state = _$state_;
  WorkPackageService = _WorkPackageService_;
  ApiNotificationsService = _ApiNotificationsService_;

  return ChildRelationsHandler;
}

childRelationsHandlerService.$inject = [
  '$state',
  'WorkPackageService',
  'ApiNotificationsService'
];

opViewModelsModule.factory('ChildRelationsHandler', childRelationsHandlerService);
