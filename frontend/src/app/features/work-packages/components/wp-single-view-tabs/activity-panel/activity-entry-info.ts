// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export class ActivityEntryInfo {
  date = this.activityDate(this.activity);

  number = this.orderedIndex(this.index, this.isReversed);

  dateOfPrevious = this.getDateOfPrevious();

  href = this.activity.href as string;

  version = this.activity.version as string;

  identifier = `${this.href}-${this.version}`;

  isNextDate = this.date !== this.dateOfPrevious;

  isInitial = this.getIsInitial();

  constructor(public timezoneService:TimezoneService,
    public isReversed:boolean,
    public activities:HalResource[],
    public activity:HalResource,
    public index:number) {
  }

  public getDateOfPrevious():string|null {
    if (this.index > 0) {
      return this.activityDate(this.activities[this.index - 1]);
    }

    return null;
  }

  public getIsInitial() {
    let activityNo = this.number;
    if (this.activity._type.indexOf('Activity') !== 0) {
      return false;
    }

    if (activityNo === 1) {
      return true;
    }

    while (--activityNo > 0) {
      const idx = this.orderedIndex(activityNo, this.isReversed) - 1;
      const activity = this.activities[idx];
      if (!_.isNil(activity) && activity._type.indexOf('Activity') === 0) {
        return false;
      }
    }

    return true;
  }

  protected activityDate(activity:any) {
    // Force long date regardless of current date settings for headers
    return moment(activity.createdAt).format('LL');
  }

  protected orderedIndex(activityNo:number, forceReverse = false) {
    if (forceReverse || this.isReversed) {
      return this.activities.length - activityNo;
    }

    return activityNo + 1;
  }
}
