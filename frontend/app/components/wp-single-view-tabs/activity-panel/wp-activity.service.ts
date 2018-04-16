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

import {ActivityEntryInfo} from './activity-entry-info';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {Injectable} from '@angular/core';
import {input, InputState} from 'reactivestates';
import {ConfigurationService} from 'core-components/common/config/configuration.service';

@Injectable()
export class WorkPackagesActivityService {

  // Cache activities for the last work package
  // to allow fast switching between work packages without refreshing.
  protected cache:{ id:string|null, state:InputState<HalResource[]> } = {
    id: null,
    state: input<HalResource[]>()
  };

  constructor(public ConfigurationService:ConfigurationService) {
  }

  public get order() {
    return this.isReversed ? 'desc' : 'asc';
  }

  public get isReversed() {
    return this.ConfigurationService.commentsSortedInDescendingOrder();
  }

  public require(workPackage:WorkPackageResource):Promise<HalResource[]> {
    const id = workPackage.id.toString();
    const state = this.cache.state;
    const cached = this.cache.id !== id && state.hasValue() || !state.isValueOlderThan(120 * 1000);

    if (cached) {
      return state.values$().toPromise();
    } else {
      return this.loadActivities(workPackage)
        .then((results:HalResource[]) => {
          state.putValue(results);
          this.cache.id = id;

          return results;
        });
    }
  }

  /**
   * Aggregate user and revision activities for the given work package resource.
   * Resolves both promises and returns a sorted list of activities
   * whose order depends on the 'commentsSortedInDescendingOrder' property.
   */
  protected loadActivities(workPackage:WorkPackageResource):Promise<HalResource[]> {
    var aggregated:any[] = [], promises:Promise<any>[] = [];

    var add = function (data:any) {
      aggregated.push(data.elements);
    };

    promises.push(workPackage.activities.$load().then(add));

    if (workPackage.revisions) {
      promises.push(workPackage.revisions.$load().then(add));
    }
    return Promise.all(promises).then(() => {
      return this.sortedActivityList(aggregated);
    });
  }

  protected sortedActivityList(activities:HalResource[], attr:string = 'createdAt'):HalResource[] {
    let sorted = _.sortBy(_.flatten(activities), attr);

    if (this.isReversed) {
      return sorted.reverse();
    } else {
      return sorted;
    }
  }

  public info(activities:HalResource[], activity:HalResource, index:number) {
    return new ActivityEntryInfo(this.isReversed, activities, activity, index);
  };
}
