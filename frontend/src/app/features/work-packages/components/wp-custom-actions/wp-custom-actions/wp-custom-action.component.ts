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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, HostListener, Input, OnInit } from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CustomActionResource } from 'core-app/features/hal/resources/custom-action-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  WorkPackagesActivityService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Component({
  selector: 'wp-custom-action',
  templateUrl: './wp-custom-action.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpCustomActionComponent extends UntilDestroyedMixin implements OnInit {
  @Input() workPackage:WorkPackageResource;

  @Input() action:CustomActionResource;

  constructor(
    private halResourceService:HalResourceService,
    private apiV3Service:ApiV3Service,
    private wpActivity:WorkPackagesActivityService,
    private notificationService:WorkPackageNotificationService,
    private halEditing:HalResourceEditingService,
    private halEvents:HalEventsService,
    private cdRef:ChangeDetectorRef,
  ) {
    super();
  }

  ngOnInit() {
    this
      .halEvents
      .events$
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => this.cdRef.detectChanges());
  }

  private fetchAction() {
    if (this.action.href === null) return;

    void this.halResourceService
      .get<CustomActionResource>(this.action.href)
      .subscribe((action) => {
        this.action = action;
      });
  }

  public get change():ResourceChangeset<WorkPackageResource> {
    return this.halEditing.changeFor(this.workPackage);
  }

  public update():void {
    if (this.action.href === null) return;

    const payload = {
      lockVersion: this.workPackage.lockVersion,
      _links: {
        workPackage: {
          href: this.workPackage.previewPath(),
        },
      },
    };

    // Mark changeset as in flight
    this.change.inFlight = true;

    this.halResourceService
      .post<WorkPackageResource>(`${this.action.href}/execute`, payload)
      .subscribe(
        (savedWp:WorkPackageResource) => {
          this.notificationService.showSave(savedWp, false);
          this.workPackage = savedWp;
          this.wpActivity.clear(this.workPackage.id);
          // Loading the schema might be necessary in cases where the button switches
          // project or type.
          void this.apiV3Service.work_packages.cache.updateWorkPackage(savedWp).then(() => {
            this.halEditing.stopEditing(savedWp);
            this.halEvents.push(savedWp, { eventType: 'updated' });
            this.change.inFlight = false;
            this.cdRef.detectChanges();
          });
        },
        (errorResource) => {
          this.notificationService.handleRawError(errorResource, this.workPackage);
          this.change.inFlight = false;
          this.cdRef.detectChanges();
        },
      );
  }

  @HostListener('mouseenter') onMouseEnter():void {
    this.fetchAction();
  }
}
