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

import { ChangeDetectionStrategy, Component, ElementRef, Input, ViewChild, OnInit } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  ActivityPanelBaseController,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/activity-base.controller';

@Component({
  templateUrl: './activity-tab.html',
  selector: 'wp-activity-tab',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageActivityTabComponent extends ActivityPanelBaseController implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  public tabName = this.I18n.t('js.work_packages.tabs.activity');

  @ViewChild('activitiesTabContent', { static: true }) public activitiesTabContentElement!:ElementRef<HTMLElement>;

  ngOnInit() {
    const { workPackageId } = this.uiRouterGlobals.params as unknown as { workPackageId:string };
    this.workPackageId = (this.workPackage.id!) || workPackageId;

    super.ngOnInit();
    if (window.location.hash) {
      this.activitiesTabContentElement.nativeElement.scrollIntoView();
    }
  }
}
