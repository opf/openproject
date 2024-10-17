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

import { Component, Input, OnInit } from '@angular/core';
import { StateService } from '@uirouter/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Component({
  templateUrl: './overview-tab.html',
  selector: 'wp-overview-tab',
})
export class WorkPackageOverviewTabComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  public workPackageId:string;

  public tabName = this.I18n.t('js.label_latest_activity');

  public primerizedActivitiesEnabled:boolean;

  public constructor(
    readonly I18n:I18nService,
    readonly $state:StateService,
    readonly apiV3Service:ApiV3Service,
    readonly configurationService:ConfigurationService,
  ) {
    super();
  }

  ngOnInit() {
    this.workPackageId = this.workPackage?.id || this.$state.params.workPackageId as string;

    this.primerizedActivitiesEnabled = this.configurationService.activeFeatureFlags.includes('primerizedWorkPackageActivities');

    this
      .apiV3Service
      .work_packages
      .id(this.workPackageId)
      .requireAndStream()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((wp) => this.workPackage = wp);
  }
}
