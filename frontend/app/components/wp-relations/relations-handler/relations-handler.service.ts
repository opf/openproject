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

import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {opViewModelsModule} from "../../../angular-modules";

var $timeout:ng.ITimeoutService;
var WorkPackageService:any;
var ApiNotificationsService:any;

export class RelationsHandler {
  public type:string = 'relation';
  public isSingletonRelation:boolean = false;

  constructor(public workPackage:WorkPackageResource, public relations, public relationsId) {
  }

  public isEmpty() {
    return !this.relations || this.relations.length === 0;
  }

  public getCount() {
    return this.relations ? this.relations.length : 0;
  }

  public canAddRelation() {
    return !!this.workPackage.$links.addRelation;
  }

  public canDeleteRelation(relation) {
    return !!relation.$links.remove;
  }

  public addRelation(scope) {
    WorkPackageService.addWorkPackageRelation(this.workPackage,
      scope.relationToAddId,
      this.relationsId)
      .then(function () {
        scope.relationToAddId = '';
        scope.updateFocus(-1);
        scope.$emit('workPackageRefreshRequired');
      }, function (error) {
        ApiNotificationsService.addError(error);
      });
  }

  public removeRelation(scope) {
    var index = this.relations.indexOf(scope.relation);
    var handler = this;

    WorkPackageService.removeWorkPackageRelation(scope.relation).then(() => {
      handler.relations.splice(index, 1);
      scope.updateFocus(index);
      scope.$emit('workPackageRefreshRequired');
    }, function (error) {
      ApiNotificationsService.addError(scope, error);
    });
  }

  public applyCustomExtensions() {
    if (this.canAddRelation) {
      var workPackage = this.workPackage;
      var relationsId = this.relationsId;
      var handler = this;
    }
  }

  public getRelatedWorkPackage(workPackage, relation) {
    var self = workPackage.links.self.href;

    if (relation.links.relatedTo.href === self) {
      return relation.links.relatedFrom.fetch();
    } else {
      return relation.links.relatedTo.fetch();
    }
  }
}

function relationsHandlerService(_$timeout_,
                                 _WorkPackageService_,
                                 _ApiNotificationsService_) {
  $timeout = _$timeout_;
  WorkPackageService = _WorkPackageService_;
  ApiNotificationsService = _ApiNotificationsService_;
}

relationsHandlerService.$inject = ['$timeout', 'WorkPackageService', 'ApiNotificationsService'];

opViewModelsModule.factory('RelationsHandler', relationsHandlerService);
