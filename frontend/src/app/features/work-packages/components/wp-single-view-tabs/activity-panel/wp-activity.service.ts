//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { Injectable } from '@angular/core';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WorkPackageLinkedResourceCache } from 'core-app/features/work-packages/components/wp-single-view-tabs/wp-linked-resource-cache.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ActivityEntryInfo } from './activity-entry-info';

@Injectable()
export class WorkPackagesActivityService extends WorkPackageLinkedResourceCache<HalResource[]> {
  constructor(public ConfigurationService:ConfigurationService,
    readonly timezoneService:TimezoneService) {
    super();
  }

  public get order() {
    return this.isReversed ? 'desc' : 'asc';
  }

  public get isReversed():boolean {
    return !!this.ConfigurationService.commentsSortedInDescendingOrder();
  }

  /**
   * Aggregate user and revision activities for the given work package resource.
   * Resolves both promises and returns a sorted list of activities
   * whose order depends on the 'commentsSortedInDescendingOrder' property.
   */
  protected load(workPackage:WorkPackageResource):Promise<HalResource[]> {
    const aggregated:any[] = []; const
      promises:Promise<any>[] = [];

    const add = function (data:any) {
      aggregated.push(data.elements);
    };

    promises.push(workPackage.activities.$update().then(add));

    if (workPackage.revisions) {
      promises.push(workPackage.revisions.$update().then(add));
    }
    return Promise.all(promises).then(() => this.sortedActivityList(aggregated));
  }

  protected sortedActivityList(activities:HalResource[], attr = 'createdAt'):HalResource[] {
    const sorted = _.sortBy(_.flatten(activities), attr);

    if (this.isReversed) {
      return sorted.reverse();
    }
    return sorted;
  }

  public info(activities:HalResource[], activity:HalResource, index:number) {
    return new ActivityEntryInfo(this.timezoneService, this.isReversed, activities, activity, index);
  }
}
