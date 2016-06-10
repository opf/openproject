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

var WorkPackageService:any;
var ApiNotificationsService:any;
var PathHelper:any;

export class ParentRelationsHandler extends RelationsHandler {
  public type:string =  'parent';

  constructor(workPackage, parent, relationsId) {
    super(workPackage, parent && [parent], relationsId);
  }

  public removeRelation(scope) {
    var index = this.relations.indexOf(scope.relation);
    var payload = this.params(scope.workPackage.lockVersion);

    WorkPackageService.updateWithPayload(scope.workPackage, payload)
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

  public addRelation(scope) {
    var payload = this.params(scope.workPackage.lockVersion, scope.relationToAddId);

    WorkPackageService.updateWithPayload(this.workPackage, payload)
      .then(() => {
        scope.relationToAddId = '';

        scope.updateFocus(-1);
        scope.$emit('workPackageRefreshRequired');
      })
      .catch(error => {
        ApiNotificationsService.addError(error);
      });
  }

  public canAddRelation() {
    return !!this.workPackage.changeParent;
  }

  public canDeleteRelation() {
    return this.canAddRelation();
  }

  public getRelatedWorkPackage(relation) {
    return relation.$load();
  }

  private params(lockVersion, id) {
    var parentPath = null;

    if (id) {
      parentPath = PathHelper.apiV3WorkPackagePath(id);
    }

    return {
      lockVersion: lockVersion,
      _links: {
        parent: {
          href: parentPath
        }
      }
    };
  }
}

function parentRelationsHandlerService(_WorkPackageService_,
                                       _ApiNotificationsService_,
                                       _PathHelper_) {
  WorkPackageService = _WorkPackageService_;
  ApiNotificationsService = _ApiNotificationsService_;
  PathHelper = _PathHelper_;
  
  return ParentRelationsHandler;
}

parentRelationsHandlerService.$inject = [
  'WorkPackageService',
  'ApiNotificationsService',
  'PathHelper'
];

opViewModelsModule.factory('ParentRelationsHandler', parentRelationsHandlerService);
