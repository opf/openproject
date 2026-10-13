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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  Component,
  inject,
  Input,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WORK_PACKAGE_UPDATED_EVENT } from 'core-stimulus/helpers/my-work-entry-menus';

/**
 * Places the Rails-rendered AI Assistance menu into the work package toolbar, and reloads
 * the work package after a proposal from that menu changed it, so the next inline edit does
 * not conflict.
 */
@Component({
  selector: 'op-wp-ai-assistance-slot',
  templateUrl: './wp-ai-assistance-slot.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageAiAssistanceSlotComponent implements OnInit, OnDestroy {
  private readonly pathHelper = inject(PathHelperService);
  private readonly configuration = inject(ConfigurationService);
  private readonly apiV3Service = inject(ApiV3Service);
  private readonly halEvents = inject(HalEventsService);

  @Input() public workPackage:WorkPackageResource;

  @Input() public compact = false;

  public enabled = false;

  public turboFrameSrc:string;

  private readonly onUpdated = (event:Event):void => {
    const detail = (event as CustomEvent<{ work_package_id?:number|string }>).detail;
    if (String(detail?.work_package_id) !== String(this.workPackage.id)) {
      return;
    }

    void this.apiV3Service
      .work_packages
      .id(this.workPackage.id!)
      .refresh()
      .then((workPackage) => this.halEvents.push(workPackage, { eventType: 'updated' }));
  };

  ngOnInit():void {
    this.enabled = this.configuration.activeFeatureFlags.includes('aiAssistance');
    if (!this.enabled) {
      return;
    }

    const url = new URL(
      `${this.pathHelper.staticBase}/work_packages/${this.workPackage.id}/ai_assistance/menu`,
      window.location.origin,
    );
    if (this.compact) {
      url.searchParams.set('compact', 'true');
    }
    this.turboFrameSrc = url.toString();

    document.addEventListener(WORK_PACKAGE_UPDATED_EVENT, this.onUpdated);
  }

  ngOnDestroy():void {
    document.removeEventListener(WORK_PACKAGE_UPDATED_EVENT, this.onUpdated);
  }
}
