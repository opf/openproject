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

import {WorkPackageRelationGroup} from './wp-relation-group.service';
import {wpTabsModule} from '../../../angular-modules';

var $state:ng.ui.IStateService;
var $q:ng.IQService;

export class WorkPackageChildRelationsGroup extends WorkPackageRelationGroup {
  public get canAddRelation() {
    return !!this.workPackage.addChild;
  }

  public canRemoveRelation() {
    return !!this.workPackage.update;
  }

  public getRelatedWorkPackage(relation) {
    return relation.$load();
  }

  public addWpRelation():ng.IPromise<any> {
    return this.workPackage.project.$load()
      .then(() => {
        const args = [
          'work-packages.list.new',
          {
            parent_id: this.workPackage.id,
            projectPath: this.workPackage.project.identifier
          }
        ];

        if ($state.includes('work-packages.show')) {
          args[0] = 'work-packages.new';
        }

        (<any>$state).go(...args);
      });
  }

  public removeWpRelation(relation) {
    const deferred = $q.defer();
    const index = this.relations.indexOf(relation);

    relation.$load()
      .then(workPackage => {
        workPackage.parentId = null;

        workPackage.save()
          .then(() => {
            this.relations.splice(index, 1);
            deferred.resolve(index);
          })
          .catch(deferred.reject);
      })
      .catch(deferred.reject);

    return deferred.promise;
  }

  protected init() {
    if (Array.isArray(this.workPackage.children)) {
      this.relations.push(...this.workPackage.children);
    }
  }
}

function wpChildRelationsGroupService(...args) {
  [$state, $q] = args;
  return WorkPackageChildRelationsGroup;
}

wpChildRelationsGroupService.$inject = ['$state', '$q'];


wpTabsModule.factory('WorkPackageChildRelationsGroup', wpChildRelationsGroupService);
