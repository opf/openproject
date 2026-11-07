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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, HostListener, Input, OnInit, inject } from '@angular/core';
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
import { firstValueFrom } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-custom-action',
  templateUrl: './wp-custom-action.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WpCustomActionComponent extends UntilDestroyedMixin implements OnInit {
  private halResourceService = inject(HalResourceService);
  private apiV3Service = inject(ApiV3Service);
  private wpActivity = inject(WorkPackagesActivityService);
  private notificationService = inject(WorkPackageNotificationService);
  private halEditing = inject(HalResourceEditingService);
  private halEvents = inject(HalEventsService);
  private cdRef = inject(ChangeDetectorRef);

  @Input() workPackage:WorkPackageResource;

  @Input() action:CustomActionResource;

  ngOnInit() {
    this
      .halEvents
      .events$
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => this.cdRef.detectChanges());
    this.fetchAction();
  }

  private fetchAction() {
    if (this.action.href === null) return;

    void this.halResourceService
      .get<CustomActionResource>(this.action.href)
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((action) => {
        this.action = action;
      });
  }

  public get description():string|undefined {
    return this.action.description || undefined;
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

    const change = this.change;
    change.inFlight = true;

    void firstValueFrom(this.halResourceService.post<WorkPackageResource>(`${this.action.href}/execute`, payload))
      .then(async (savedWp) => {
        this.notificationService.showSave(savedWp, false);
        this.workPackage = savedWp;
        this.wpActivity.clear(savedWp.id);
        await this.apiV3Service.work_packages.cache.updateWorkPackage(savedWp);
        this.halEditing.stopEditing(savedWp);
        this.halEvents.push(savedWp, { eventType: 'updated' });
      })
      .catch((error:unknown) => {
        this.notificationService.handleRawError(error, this.workPackage);
      })
      .finally(() => {
        change.inFlight = false;
        this.cdRef.markForCheck();
      });
  }

  @HostListener('mouseenter') onMouseEnter():void {
    this.fetchAction();
  }
}
