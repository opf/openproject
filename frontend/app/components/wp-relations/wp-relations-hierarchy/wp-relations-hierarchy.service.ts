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

import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {States} from "../../states.service";
import {WorkPackageTableRefreshService} from "../../wp-table/wp-table-refresh-request.service";

export class WorkPackageRelationsHierarchyService {
  constructor(protected $state: ng.ui.IStateService,
              protected $q: ng.IQService,
              protected states: States,
              protected wpTableRefresh: WorkPackageTableRefreshService,
              protected $rootScope: ng.IRootScopeService,
              protected wpNotificationsService: WorkPackageNotificationService,
              protected wpCacheService: WorkPackageCacheService,
              protected v3Path:any) {

  }

  public changeParent(workPackage:WorkPackageResourceInterface, parentId:string | null) {
    let payload:any = {
      lockVersion: workPackage.lockVersion
    };

    if (parentId) {
      payload['_links'] = {
        parent: {
            href: this.v3Path.wp({wp: parentId})
        }
      };
    } else {
      payload['_links'] = {
        parent: {
            href: null
        }
      };
    }

    return workPackage
      .changeParent(payload)
      .then((wp:WorkPackageResourceInterface) => {
        this.wpCacheService.updateWorkPackage(wp);
        this.wpNotificationsService.showSave(wp);
        this.wpTableRefresh.request(true, `Changed parent of ${workPackage.id} to ${parentId}`);
        return wp;
      })
      .catch((err) => {
        this.wpNotificationsService.handleErrorResponse(err, workPackage);
      });
  }

  public removeParent(workPackage: WorkPackageResourceInterface) {
    return this.changeParent(workPackage, null);
  }

  public addExistingChildWp(workPackage: WorkPackageResourceInterface, childWpId: string): ng.IPromise<WorkPackageResourceInterface> {
    const deferred = this.$q.defer();
    const state = this.wpCacheService.loadWorkPackage(childWpId);

    state.valuesPromise().then((wpToBecomeChild: WorkPackageResourceInterface) => {
      this.wpTableRefresh.request(true, `Added new child to ${workPackage.id}`);
      deferred.resolve(this.changeParent(wpToBecomeChild, workPackage.id));
    });

    return deferred.promise;
  }

  public addNewChildWp(workPackage: WorkPackageResourceInterface) {
    workPackage.project.$load()
      .then(() => {
        const args = [
          'work-packages.list.new',
          {
            parent_id: workPackage.id,
            projectPath: workPackage.project.identifier
          }
        ];

        if (this.$state.includes('work-packages.show')) {
          args[0] = 'work-packages.new';
        }

        (<any>this.$state).go(...args);
      });
  }

  public removeChild(childWorkPackage:WorkPackageResourceInterface) {
    return childWorkPackage.$load().then(() => {
      return childWorkPackage.changeParent({
        _links: {
          parent: {
              href: null
          }
        },
        lockVersion: childWorkPackage.lockVersion
      }).then(wp => {
        this.wpCacheService.updateWorkPackage(wp);
      });
    });
  }

}

wpDirectivesModule.service('wpRelationsHierarchyService', WorkPackageRelationsHierarchyService);


