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

import {ChangeDetectionStrategy, Component, OnInit} from "@angular/core";
import {take} from "rxjs/operators";
import {BcfDetectorService} from "core-app/modules/bcf/helper/bcf-detector.service";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {PartitionedQuerySpacePageComponent} from "core-app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component";

@Component({
  selector: 'wp-view-page',
  templateUrl: '/app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    // Absolute paths do not work for styleURLs :-(
    '../partitioned-query-space-page/partitioned-query-space-page.component.sass'
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    /** We need to provide the wpNotification service here to get correct save notifications for WP resources */
    {provide: HalResourceNotificationService, useClass: WorkPackageNotificationService},
    QueryParamListenerService
  ]
})
export class WorkPackageViewPageComponent extends PartitionedQuerySpacePageComponent implements OnInit {
  @InjectField() bcfDetectorService:BcfDetectorService;

  transitionListenerState = 'work-packages.partitioned.list';

  ngOnInit() {
    super.ngOnInit();
    this.text.button_settings = this.I18n.t('js.button_settings');
  }

  public allowed(model:string, permission:string) {
    return this.authorisationService.can(model, permission);
  }

  public bcfActivated() {
    return this.bcfDetectorService.isBcfActivated;
  }
  protected additionalLoadingTime():Promise<unknown> {
    if (this.wpTableTimeline.isVisible) {
      return this.querySpace.timelineRendered.pipe(take(1)).toPromise();
    } else {
      return this.querySpace.tableRendered.valuesPromise() as Promise<unknown>;
    }
  }
}
