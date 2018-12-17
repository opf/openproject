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

import {Component, Inject, OnDestroy} from '@angular/core';
import {StateService, Transition} from '@uirouter/core';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';

@Component({
  templateUrl: './overview-tab.html',
  selector: 'wp-overview-tab',
})
export class WorkPackageOverviewTabComponent implements OnDestroy {
  public workPackageId:string;
  public workPackage:WorkPackageResource;
  public tabName = this.I18n.t('js.label_latest_activity');

  public constructor(readonly I18n:I18nService,
                     readonly $state:StateService,
                     readonly wpCacheService:WorkPackageCacheService) {

    this.workPackageId = this.$state.params.workPackageId;
    wpCacheService.loadWorkPackage(this.workPackageId)
      .values$()
      .pipe(
        takeUntil(componentDestroyed(this))
      )
      .subscribe((wp) => this.workPackage = wp);
  }

  ngOnDestroy() {
    // Nothing to do
  }
}
