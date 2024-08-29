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

import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import {
  ApplicationRef,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  Input,
  NgZone,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  WorkPackageCommentFieldHandler,
} from 'core-app/features/work-packages/components/work-package-comment/work-package-comment-field-handler';
import {
  WorkPackagesActivityService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { CommentService } from 'core-app/features/work-packages/components/wp-activity/comment-service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { DeviceService } from 'core-app/core/browser/device.service';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'user-activity',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './user-activity.component.html',
  styleUrls: ['./user-activity.component.sass'],
})
export class UserActivityComponent extends WorkPackageCommentFieldHandler implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  @Input() public activity:HalResource;

  @Input() public activityNo:number;

  @Input() public isInitial:boolean;

  @Input() public hasUnreadNotification:boolean;

  private additionalScrollMargin = 200;

  public userCanEdit = false;

  public userCanQuote = false;

  public userId:string|number;

  public user:UserResource;

  public userName:string;

  public userAvatar:string;

  public details:any[] = [];

  public isComment:boolean;

  public isBcfComment:boolean;

  public postedComment:SafeHtml;

  public focused = false;

  public text = {
    label_created_on: this.I18n.t('js.label_created_on'),
    label_updated_on: this.I18n.t('js.label_updated_on'),
    quote_comment: this.I18n.t('js.label_quote_comment'),
    edit_comment: this.I18n.t('js.label_edit_comment'),
  };

  private $element:JQuery;

  constructor(
    readonly elementRef:ElementRef,
    readonly injector:Injector,
    readonly sanitization:DomSanitizer,
    readonly PathHelper:PathHelperService,
    readonly wpLinkedActivities:WorkPackagesActivityService,
    readonly commentService:CommentService,
    readonly configurationService:ConfigurationService,
    readonly apiV3Service:ApiV3Service,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly ngZone:NgZone,
    readonly deviceService:DeviceService,
    protected appRef:ApplicationRef,
  ) {
    super(elementRef, injector);
  }

  public ngOnInit() {
    super.ngOnInit();

    this.htmlId = `user_activity_edit_field_${this.activityNo}`;
    this.updateCommentText();
    this.isComment = this.activity._type === 'Activity::Comment';
    this.isBcfComment = this.activity._type === 'Activity::BcfComment';

    this.$element = jQuery(this.elementRef.nativeElement);
    this.reset();
    this.userCanEdit = !!this.activity.update;
    this.userCanQuote = !!this.workPackage.addComment;

    this.$element.bind('focusin', this.focus.bind(this));
    this.$element.bind('focusout', this.blur.bind(this));

    _.each(this.activity.details, (detail:{ html:string }) => {
      this.details.push(this.sanitization.bypassSecurityTrustHtml(detail.html));
    });

    this
      .apiV3Service
      .users
      .id(idFromLink(this.activity.user.href))
      .get()
      .subscribe((user:UserResource) => {
        this.user = user;
        this.userId = user.id!;
        this.userName = user.name;
        this.userAvatar = user.avatar;
        this.cdRef.detectChanges();
      });

    if (window.location.hash === `#activity-${this.activityNo}`) {
      this.ngZone.runOutsideAngular(() => {
        setTimeout(() => {
          if (this.deviceService.isMobile) {
            (this.elementRef.nativeElement as HTMLElement).scrollIntoView(true);
            return;
          }
          const activityElement = document.querySelectorAll(`[data-qa-activity-number='${this.activityNo}']`)[0] as HTMLElement;
          const scrollContainer = document.querySelectorAll('[data-notification-selector=\'notification-scroll-container\']')[0];
          const scrollOffset = activityElement.offsetTop - (scrollContainer as HTMLElement).offsetTop - this.additionalScrollMargin;
          scrollContainer.scrollTop = scrollOffset;
        });
      });
    }
  }

  public shouldHideIcons():boolean {
    return !((this.isComment || this.isBcfComment) && this.focussing());
  }

  public activate() {
    super.activate(this.activity.comment.raw);
    this.cdRef.detectChanges();
  }

  public handleUserSubmit() {
    if (this.inFlight || !this.rawComment) {
      return Promise.resolve();
    }
    return this.updateComment();
  }

  public quoteComment() {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    this.commentService.quoteEvents$.next(this.quotedText(this.activity.comment.raw));
  }

  public get bcfSnapshotUrl() {
    if (_.get(this.activity, 'bcfViewpoints[0]')) {
      return `${_.get(this.activity, 'bcfViewpoints[0]').href}/snapshot`;
    }
    return null;
  }

  public async updateComment():Promise<unknown> {
    this.inFlight = true;

    await this.onSubmit();
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-return
    return this.commentService.updateComment(this.activity, this.rawComment || '')
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      .then((newActivity:HalResource) => {
        this.activity = newActivity;
        this.updateCommentText();
        this.wpLinkedActivities.require(this.workPackage, true);
        this
          .apiV3Service
          .work_packages
          .cache
          .updateWorkPackage(this.workPackage);
      })
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      .finally(() => {
        this.deactivate(true);
        this.inFlight = false;
      });
  }

  public focusEditIcon() {
    // Find the according edit icon and focus it
    jQuery(`.edit-activity--${this.activityNo} a`).focus();
  }

  public focus() {
    this.focused = true;
    this.cdRef.detectChanges();
  }

  public blur() {
    this.focused = false;
    this.cdRef.detectChanges();
  }

  public focussing() {
    return this.focused;
  }

  setErrors(_newErrors:string[]):void {
    // interface
  }

  public quotedText(rawComment:string) {
    const quoted = rawComment.split('\n')
      .map((line:string) => `\n> ${line}`)
      .join('');
    const userWrote = this.I18n.instance_locale_translate('js.text_user_wrote', { value: this.userName });
    return `${userWrote}\n${quoted}`;
  }

  deactivate(focus:boolean):void {
    super.deactivate(focus);

    if (focus) {
      this.focusEditIcon();
    }
  }

  private updateCommentText() {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument,@typescript-eslint/no-unsafe-member-access
    this.postedComment = this.sanitization.bypassSecurityTrustHtml(this.activity.comment.html);
  }
}
