// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { ChangeDetectorRef, Directive, OnInit } from '@angular/core';
import { Transition } from '@uirouter/core';
import { combineLatest } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ActivityEntryInfo } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/activity-entry-info';
import { WorkPackagesActivityService } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { InAppNotification, NOTIFICATIONS_MAX_SIZE } from 'core-app/features/in-app-notifications/store/in-app-notification.model';

@Directive()
export class ActivityPanelBaseController extends UntilDestroyedMixin implements OnInit {
  public workPackage:WorkPackageResource;

  public workPackageId:string;

  // All activities retrieved for the work package
  public unfilteredActivities:HalResource[] = [];

  // Visible activities
  public visibleActivities:ActivityEntryInfo[] = [];

  public notifications:InAppNotification[] = [];

  public reverse:boolean;

  public showToggler:boolean;

  public onlyComments = false;

  public togglerText:string;

  public text = {
    commentsOnly: this.I18n.t('js.label_activity_show_only_comments'),
    showAll: this.I18n.t('js.label_activity_show_all'),
  };

  constructor(readonly apiV3Service:APIV3Service,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly $transition:Transition,
    readonly wpActivity:WorkPackagesActivityService) {
    super();

    this.reverse = wpActivity.isReversed;
    this.togglerText = this.text.commentsOnly;
  }

  ngOnInit() {
    combineLatest([
      this
        .apiV3Service
        .work_packages
        .id(this.workPackageId)
        .requireAndStream()
        .pipe(this.untilDestroyed()),
      this
        .apiV3Service
        .notifications
        .facet(
          'unread',
          {
            pageSize: NOTIFICATIONS_MAX_SIZE,
            filters: [
              ['resourceId', '=', [this.workPackageId]],
              ['resourceType', '=', ['WorkPackage']],
            ],
          },
        ),
    ])
      .subscribe(([wp, notificationCollection]) => {
        this.notifications = notificationCollection._embedded.elements;
        this.workPackage = wp;
        void this.wpActivity.require(this.workPackage).then((activities:HalResource[]) => {
          this.updateActivities(activities);
          this.cdRef.detectChanges();
          this.scrollToUnreadNotification();
        });
      });
  }

  protected updateActivities(activities:HalResource[]) {
    this.unfilteredActivities = activities;

    const visible = this.getVisibleActivities();
    this.visibleActivities = visible.map((el:HalResource, i:number) => this.info(el, i));
    this.showToggler = this.shouldShowToggler();
  }

  protected shouldShowToggler() {
    const count_all = this.unfilteredActivities.length;
    const count_with_comments = this.getActivitiesWithComments().length;

    return count_all > 1
      && count_with_comments > 0
      && count_with_comments < this.unfilteredActivities.length;
  }

  protected getVisibleActivities() {
    if (!this.onlyComments) {
      return this.unfilteredActivities;
    }
    return this.getActivitiesWithComments();
  }

  protected getActivitiesWithComments() {
    return this.unfilteredActivities
      .filter((activity:HalResource) => !!_.get(activity, 'comment.html'));
  }

  protected hasUnreadNotification(activityHref:string):boolean {
    return !!this.notifications.find((notification) => notification._links.activity?.href === activityHref);
  }

  protected scrollToUnreadNotification():void {
    // scroll to the unread notification only if there is no deep link
    if (!(window.location.href.indexOf('activity#') > -1)) {
      const unreadNotifications = document.querySelectorAll('[data-qa-selector="user-activity-bubble"]');
      const unreadNotificationsLength = unreadNotifications?.length;
      if (unreadNotificationsLength && this.notifications.length) {
        if (this.reverse) {
          unreadNotifications[unreadNotificationsLength - 1].classList.add('op-user-activity--unread-notification-bubble_scrolled');
          unreadNotifications[unreadNotificationsLength - 1].scrollIntoView();
        } else {
          unreadNotifications[0].classList.add('op-user-activity--unread-notification-bubble_scrolled');
          unreadNotifications[0].scrollIntoView();
        }
      }
    }
  }

  public toggleComments() {
    this.onlyComments = !this.onlyComments;
    this.updateActivities(this.unfilteredActivities);

    if (this.onlyComments) {
      this.togglerText = this.text.showAll;
    } else {
      this.togglerText = this.text.commentsOnly;
    }
  }

  public info(activity:HalResource, index:number) {
    return this.wpActivity.info(this.unfilteredActivities, activity, index);
  }
}
