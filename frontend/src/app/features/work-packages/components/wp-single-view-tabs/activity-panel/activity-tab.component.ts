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

import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { trackByProperty } from 'core-app/shared/helpers/angular/tracking-functions';
import {
  ActivityPanelBaseController,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/activity-base.controller';

@Component({
  templateUrl: './activity-tab.html',
  selector: 'wp-activity-tab',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageActivityTabComponent extends ActivityPanelBaseController {
  @Input() public workPackage:WorkPackageResource;

  public tabName = this.I18n.t('js.work_packages.tabs.activity');

  public trackByIdentifier = trackByProperty('identifier');

  ngOnInit() {
    const { workPackageId } = this.uiRouterGlobals.params as unknown as { workPackageId:string };
    this.workPackageId = (this.workPackage.id as string) || workPackageId;
    super.ngOnInit();
  }
}
