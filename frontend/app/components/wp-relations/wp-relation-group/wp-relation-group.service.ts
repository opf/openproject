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

import {wpTabsModule} from '../../../angular-modules';
import {WorkPackageRelationsConfigInterface} from '../wp-relations.service';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';

declare var URI:any;

var $q:ng.IQService;
var $http:ng.IHttpService;
var PathHelper:any;

export class WorkPackageRelationGroup {
  public relations = [];

  public get name():string {
    return this.config.name;
  }

  public get type():string {
    return this.config.type;
  }

  public get id():string {
    return this.config.id || this.name;
  }

  public get isEmpty():boolean {
    return !this.relations.length;
  }

  public get canAddRelation() {
    return !!this.workPackage.addRelation;
  }

  constructor(protected workPackage:WorkPackageResourceInterface,
              protected config:WorkPackageRelationsConfigInterface) {
    this.init();
  }

  public canRemoveRelation(relation):boolean {
    return !!relation.remove;
  }

  public getRelatedWorkPackage(relation) {
    if (relation.relatedTo.href === this.workPackage.href) {
      return relation.relatedFrom.$load();
    }
    return relation.relatedTo.$load();
  }

  public findRelatableWorkPackages(search:string) {
    const deferred = $q.defer();
    var params;

    this.workPackage.project.$load().then(() => {
      params = {
        q: search,
        scope: 'relatable',
        escape: false,
        id: this.workPackage.id,
        project_id: this.workPackage.project.id
      };

      $http({
        method: 'GET',
        url: URI(PathHelper.workPackageJsonAutoCompletePath()).search(params).toString()
      })
        .then((response:any) => deferred.resolve(response.data))
        .catch(deferred.reject);
    })
      .catch(deferred.reject);

    return deferred.promise;
  }

  public addWpRelation(wpId:number):ng.IPromise<any> {
    return this.workPackage.addRelation({
      to_id: wpId,
      relation_type: this.id
    })
      .then(relation => this.relations.push(relation));
  }

  public removeWpRelation(relation) {
    const index = this.relations.indexOf(relation);

    return relation.remove().then(() => {
      this.relations.splice(index, 1);
      return index;
    });
  }

  protected init() {
    const elements = this.workPackage.relations.elements;
    if (Array.isArray(elements)) {
      this.relations.push(
        ...elements.filter(relation => relation._type === this.type));
    }
  }
}

function wpRelationGroupService(...args) {
  [$q, $http, PathHelper] = args;
  return WorkPackageRelationGroup;
}

wpRelationGroupService.$inject = ['$q', '$http', 'PathHelper'];

wpTabsModule.factory('WorkPackageRelationGroup', wpRelationGroupService);
