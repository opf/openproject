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

import { ChangeDetectorRef, Directive, OnInit } from '@angular/core';
import { UIRouterGlobals } from '@uirouter/core';
import { Observable } from 'rxjs';
import { distinctUntilChanged, map } from 'rxjs/operators';
import { take } from 'rxjs/internal/operators/take';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  ActivityEntryInfo,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/activity-entry-info';
import {
  WorkPackagesActivityService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';
import { DeviceService } from 'core-app/core/browser/device.service';

@Directive()
export class ActivityPanelBaseController extends UntilDestroyedMixin implements OnInit {
  public workPackage:WorkPackageResource;

  public workPackageId:string;

  // All activities retrieved for the work package
  public unfilteredActivities:HalResource[] = [];

  // Visible activities
  public visibleActivities:ActivityEntryInfo[] = [];

  public reverse:boolean;

  public showToggler:boolean;

  public onlyComments = false;

  public togglerText:string;

  public text = {
    commentsOnly: this.I18n.t('js.label_activity_show_only_comments'),
    showAll: this.I18n.t('js.label_activity_show_all'),
  };

  private additionalScrollMargin = 200;

  private initialized = false;

  private comingFromNotifications = false;

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly wpActivity:WorkPackagesActivityService,
    readonly storeService:WpSingleViewService,
    readonly browserDetector:BrowserDetector,
    private wpSingleViewService:WpSingleViewService,
    readonly deviceService:DeviceService,
  ) {
    super();

    this.reverse = wpActivity.isReversed;
    this.togglerText = this.text.commentsOnly;

    if (window.location.href.includes('/notifications')) {
      this.comingFromNotifications = true;
    }
  }

  ngOnInit():void {
    this.initialized = false;
    this
      .apiV3Service
      .work_packages
      .id(this.workPackageId)
      .requireAndStream()
      .pipe(this.untilDestroyed())
      .subscribe((wp) => {
        this.workPackage = wp;
        this.reloadActivities();
      });

    this
      .wpSingleViewService
      .selectNotificationsCount$
      .pipe(
        this.untilDestroyed(),
        distinctUntilChanged(),
      )
      .subscribe(() => {
        this.reloadActivities();
      });
  }

  private scrollIfNotificationPresent() {
    this
      .storeService
      .hasNotifications$
      .pipe(take(1))
      .subscribe((hasNotification) => {
        if (hasNotification) {
          this.scrollToUnreadNotification();
        }
      });
  }

  private reloadActivities() {
    void this.wpActivity.require(this.workPackage, true).then((activities:HalResource[]) => {
      this.updateActivities(activities);
      this.cdRef.detectChanges();

      if (!this.initialized) {
        this.initialized = true;
        this.scrollIfNotificationPresent();
      }
    });
  }

  protected updateActivities(activities:HalResource[]):void {
    this.unfilteredActivities = activities;

    const visible = this.getVisibleActivities();
    this.visibleActivities = visible.map((el:HalResource, i:number) => this.info(el, i));
    this.showToggler = this.shouldShowToggler();
  }

  protected shouldShowToggler():boolean {
    const countAll = this.unfilteredActivities.length;
    const countWithComments = this.getActivitiesWithComments().length;

    return countAll > 1
      && countWithComments > 0
      && countWithComments < this.unfilteredActivities.length;
  }

  protected getVisibleActivities():HalResource[] {
    if (!this.onlyComments) {
      return this.unfilteredActivities;
    }
    return this.getActivitiesWithComments();
  }

  protected getActivitiesWithComments():HalResource[] {
    return this.unfilteredActivities
      .filter((activity:HalResource) => !!_.get(activity, 'comment.html'));
  }

  protected hasUnreadNotification(activityHref:string):Observable<boolean> {
    return this
      .storeService
      .selectNotifications$
      .pipe(
        map((notifications) => (
          !!notifications.find((notification) => notification._links.activity?.href === activityHref)
        )),
      );
  }

  protected scrollToUnreadNotification():void {
    const unreadNotifications = document.querySelectorAll("[data-notification-selector='notification-activity']");
    // scroll to the unread notification only if there is no deep link
    if (window.location.href.indexOf('activity#') > -1 || unreadNotifications.length === 0) {
      return;
    }

    const notificationElement = unreadNotifications[this.reverse ? unreadNotifications.length - 1 : 0] as HTMLElement;
    const scrollContainer = document.querySelectorAll("[data-notification-selector='notification-scroll-container']")[0];

    const scrollOffset = notificationElement.offsetTop - (scrollContainer as HTMLElement).offsetTop - this.additionalScrollMargin;
    scrollContainer.scrollTop = scrollOffset;

    // Make sure the scrollContainer is visible on mobile
    if (this.comingFromNotifications && this.deviceService.isMobile) {
      scrollContainer.scrollIntoView(true);
    }
  }

  public toggleComments():void {
    this.onlyComments = !this.onlyComments;
    this.updateActivities(this.unfilteredActivities);

    if (this.onlyComments) {
      this.togglerText = this.text.showAll;
    } else {
      this.togglerText = this.text.commentsOnly;
    }
  }

  public info(activity:HalResource, index:number):ActivityEntryInfo {
    return this.wpActivity.info(this.unfilteredActivities, activity, index);
  }
}
