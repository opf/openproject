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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, HostListener, Input, OnInit, inject } from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CustomActionResource } from 'core-app/features/hal/resources/custom-action-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import {
  HalResourceEditingService,
  ResourceChangesetCommit,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ChangeMap } from 'core-app/shared/components/fields/changeset/changeset';
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

  public get title():string {
    return this.action.description || this.action.name;
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
          const previousWp = this.workPackage;
          this.notificationService.showSave(savedWp, false);
          this.workPackage = savedWp;
          this.wpActivity.clear(this.workPackage.id);
          // Loading the schema might be necessary in cases where the button switches
          // project or type.
          void this.apiV3Service.work_packages.cache.updateWorkPackage(savedWp).then(() => {
            this.halEditing.stopEditing(savedWp);
            // Custom actions are executed server-side and thus have no Angular
            // changeset. Attach a commit describing the changed link attributes
            // (e.g. status, assignee, version) so that action boards can detect
            // the change and move the card to the correct column.
            this.halEvents.push(savedWp, {
              eventType: 'updated',
              commit: this.commitFor(previousWp, savedWp),
            });
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

  // Build a commit describing the link attributes that the custom action
  // changed, by diffing the work package before and after execution. Only the
  // `changes` map is consumed by the action board listener, where each entry's
  // `from`/`to` is compared against the column's value via its `href`.
  private commitFor(previous:WorkPackageResource, saved:WorkPackageResource):ResourceChangesetCommit<WorkPackageResource> {
    const previousLinks = (previous.$source._links || {}) as Record<string, { href?:string }>;
    const savedLinks = (saved.$source._links || {}) as Record<string, { href?:string }>;
    const changes:ChangeMap = {};

    Object.keys(savedLinks).forEach((attribute) => {
      const from = previousLinks[attribute]?.href;
      const to = savedLinks[attribute]?.href;

      if (from !== to) {
        changes[attribute] = {
          from: from ? { href: from } : undefined,
          to: to ? { href: to } : undefined,
        };
      }
    });

    return {
      id: saved.id!,
      resource: saved,
      wasNew: false,
      changes,
    } as ResourceChangesetCommit<WorkPackageResource>;
  }

  @HostListener('mouseenter') onMouseEnter():void {
    this.fetchAction();
  }
}
