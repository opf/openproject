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

import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {ActivityPanelBaseController} from 'core-components/wp-single-view-tabs/activity-panel/activity-base.controller';
import {Component, Inject, Input} from '@angular/core';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {HalResource} from 'core-components/api/api-v3/hal-resources/hal-resource.service';
import {ActivityEntryInfo} from 'core-components/wp-single-view-tabs/activity-panel/activity-entry-info';

@Component({
  templateUrl: './activity-on-overview.html',
  selector: 'newest-activity-on-overview',
})
export class NewestActivityOnOverviewComponent extends ActivityPanelBaseController {
  @Input('workPackage') public workPackage:WorkPackageResourceInterface;

  public latestActivityInfo:ActivityEntryInfo[] = [];

  constructor(readonly wpCacheService:WorkPackageCacheService,
              @Inject(I18nToken) readonly I18n:op.I18n,
              readonly wpActivity:WorkPackagesActivityService) {
    super(wpCacheService, I18n, wpActivity);
  }

  ngOnInit() {
    this.workPackageId = this.workPackage.id;
    super.ngOnInit();
  }

  protected shouldShowToggler() {
    return false;
  }

  protected updateActivities(activities:any) {
    super.updateActivities(activities);
    this.latestActivityInfo = this.latestActivities();
  }

  private latestActivities(visible:number = 3) {
    let segment = this.unfilteredActivities.slice(0, visible);
    return segment.map((el:HalResource, i:number) => this.info(el, i));
  }
}
