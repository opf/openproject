// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {TimezoneService} from 'core-components/datetime/timezone.service';

export class ActivityEntryInfo {

  constructor(public timezoneService:TimezoneService,
              public isReversed:boolean,
              public activities:any[],
              public activity:any,
              public index:number) {
  }

  public number(forceReverse:boolean = false) {
    return this.orderedIndex(this.index, forceReverse);
  }

  public get date() {
    return this.activityDate(this.activity);
  }

  public get dateOfPrevious():any {
    if (this.index > 0) {
      return this.activityDate(this.activities[this.index - 1]);
    }
  }

  public get href() {
    return this.activity.href;
  }

  public get version() {
    return this.activity.version;
  }

  public get isNextDate() {
    return this.date !== this.dateOfPrevious;
  }

  public isInitial(forceReverse:boolean = false) {
    var activityNo = this.number(forceReverse);

    if (this.activity._type.indexOf('Activity') !== 0) {
      return false;
    }

    if (activityNo === 1) {
      return true;
    }

    while (--activityNo > 0) {
      var idx = this.orderedIndex(activityNo, forceReverse) - 1;
      var activity = this.activities[idx];
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

  protected orderedIndex(activityNo:number, forceReverse:boolean = false) {
    if (forceReverse || this.isReversed) {
      return this.activities.length - activityNo;
    }

    return activityNo + 1;
  }
}
