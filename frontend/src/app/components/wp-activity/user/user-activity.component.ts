//-- copyright
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
//++

import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  Input,
  OnInit
} from "@angular/core";
import {UserCacheService} from "core-components/user/user-cache.service";
import {CommentService} from "core-components/wp-activity/comment-service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageCommentFieldHandler} from "core-components/work-packages/work-package-comment/work-package-comment-field-handler";
import {DomSanitizer, SafeHtml} from "@angular/platform-browser";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Component({
  selector: 'user-activity',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './user-activity.component.html'
})
export class UserActivityComponent extends WorkPackageCommentFieldHandler implements OnInit, AfterViewInit {
  @Input() public workPackage:WorkPackageResource;
  @Input() public activity:HalResource;
  @Input() public activityNo:number;
  @Input() public isInitial:boolean;

  public userCanEdit = false;
  public userCanQuote = false;

  public userId:string | number;
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

  constructor(readonly elementRef:ElementRef,
              readonly injector:Injector,
              readonly sanitization:DomSanitizer,
              readonly PathHelper:PathHelperService,
              readonly wpLinkedActivities:WorkPackagesActivityService,
              readonly commentService:CommentService,
              readonly wpCacheService:WorkPackageCacheService,
              readonly ConfigurationService:ConfigurationService,
              readonly userCacheService:UserCacheService,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService) {
    super(elementRef, injector);
  }

  public ngOnInit() {
    super.ngOnInit();

    this.updateCommentText();
    this.isComment = this.activity._type === 'Activity::Comment';
    this.isBcfComment = this.activity._type === 'Activity::BcfComment';

    this.$element = jQuery(this.elementRef.nativeElement);
    this.reset();
    this.userCanEdit = !!this.activity.update;
    this.userCanQuote = !!this.workPackage.addComment;

    this.$element.bind('focusin', this.focus.bind(this));
    this.$element.bind('focusout', this.blur.bind(this));

    _.each(this.activity.details, (detail:any) => {
      this.details.push(detail.html);
    });

    this.userCacheService
      .require(this.activity.user.idFromLink)
      .then((user:UserResource) => {
        this.user = user;
        this.userId = user.id!;
        this.userName = user.name;
        this.userAvatar = user.avatar;
        this.cdRef.detectChanges();
      });
  }

  public shouldHideIcons():boolean {
    return !((this.isComment || this.isBcfComment) && this.focussing());
  }

  public ngAfterViewInit() {
    if (window.location.hash === 'activity-' + this.activityNo) {
      this.elementRef.nativeElement.scrollIntoView(true);
    }
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
    this.commentService.quoteEvents.next(this.quotedText(this.activity.comment.raw));
  }

  public get bcfSnapshotUrl() {
    if (_.get(this.activity, 'bcfViewpoints[0]')) {
      return `${_.get(this.activity, 'bcfViewpoints[0]').href}/snapshot`;
    } else {
      return null;
    }
  }

  public async updateComment() {
    this.inFlight = true;

    await this.onSubmit();
    return this.commentService.updateComment(this.activity, this.rawComment || '')
      .then((newActivity:HalResource) => {
        this.activity = newActivity;
        this.updateCommentText();
        this.wpLinkedActivities.require(this.workPackage, true);
        this.wpCacheService.updateWorkPackage(this.workPackage);
      })
      .finally(() => {
        this.deactivate(true); this.inFlight = false;
      });
  }

  public focusEditIcon() {
    // Find the according edit icon and focus it
    jQuery('.edit-activity--' + this.activityNo + ' a').focus();
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

  setErrors(newErrors:string[]):void {
    // interface
  }

  public quotedText(rawComment:string) {
    let quoted = rawComment.split('\n')
      .map(function(line:string) {
        return '\n> ' + line;
      })
      .join('');
    return this.userName + ' wrote:\n' + quoted;
  }

  public get htmlId() {
    return `user_activity_edit_field_${this.activityNo}`;
  }

  deactivate(focus:boolean):void {
    super.deactivate(focus);

    if (focus) {
      this.focusEditIcon();
    }
  }

  private updateCommentText() {
    this.postedComment = this.sanitization.bypassSecurityTrustHtml(this.activity.comment.html);
  }
}
