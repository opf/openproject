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

import {opWorkPackagesModule} from '../../../angular-modules';
import {ActivityEntryInfo} from './activity-entry-info';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';


export class WorkPackagesActivityService {

  constructor(public ConfigurationService:any,
              public $filter:ng.IFilterService,
              public $q:ng.IQService) {
  }

  public get order() {
    return this.isReversed ? 'desc' : 'asc';
  }

  public get isReversed() {
    return this.ConfigurationService.commentsSortedInDescendingOrder();
  }

  /**
   * Aggregate user and revision activities for the given work package resource.
   * Resolves both promises and returns a sorted list of activities
   * whose order depends on the 'commentsSortedInDescendingOrder' property.
   */
  public aggregateActivities(workPackage:WorkPackageResourceInterface):ng.IPromise<any> {
    var aggregated:any[] = [], promises:ng.IPromise<any>[] = [];

    var add = function (data:any) {
      aggregated.push(data.elements);
    };

    this.hackNonCachedActivities(workPackage);

    promises.push(workPackage.activities.$load().then(add));

    if (workPackage.revisions) {
      promises.push(workPackage.revisions.$load().then(add));
    }
    return this.$q.all(promises).then(() => {
      return this.sortedActivityList(aggregated);
    });
  }

  protected sortedActivityList(activities:any, attr:string = 'createdAt') {
    return this.$filter('orderBy')(
      _.flatten(activities),
      attr,
      this.isReversed
    );
  }

  public info(activities:any, activity:any, index:any) {
    return new ActivityEntryInfo(this.$filter, this.isReversed, activities, activity, index);
  };

  // FIXME: ugly hack to enable circumventing cached responses which would return stale activities after a user updated a resource.
  // The correct solution is to rely on states.
  private hackNonCachedActivities(workPackage:WorkPackageResourceInterface) {
    let newLoadHeaders = () => {
      return { caching: { enabled: false } }
    };
    workPackage.activities['$loadHeaders'] = newLoadHeaders;
  }
}

opWorkPackagesModule.service('wpActivity', WorkPackagesActivityService);
