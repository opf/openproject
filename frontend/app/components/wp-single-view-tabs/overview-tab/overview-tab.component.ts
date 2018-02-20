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

import {Component, Inject, Input, OnDestroy} from '@angular/core';
import {Transition} from '@uirouter/core';
import {I18nToken} from '../../../angular4-transition-utils';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
@Component({
  template: require('!!raw-loader!./overview-tab.html'),
  selector: 'wp-overview-tab',
})
export class WorkPackageOverviewTabComponent implements OnDestroy {
  public workPackageId:string;
  public workPackage:WorkPackageResourceInterface;
  public tabName = this.I18n.t('js.label_latest_activity');

  public constructor(@Inject(I18nToken) readonly I18n:op.I18n,
                     readonly $transition:Transition,
                     readonly wpCacheService:WorkPackageCacheService) {

    this.workPackageId = this.$transition.params('to').workPackageId;
    wpCacheService.loadWorkPackage(this.workPackageId)
      .values$()
      .takeUntil(componentDestroyed(this))
      .subscribe((wp) => this.workPackage = wp);
  }

  ngOnDestroy() {
    // Nothing to do
  }
}
