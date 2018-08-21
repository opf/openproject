//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {WorkPackageCommentField} from 'core-components/work-packages/work-package-comment/wp-comment-field.module';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';
import {AfterViewInit, Component, ElementRef, Inject, Input, OnInit} from "@angular/core";
import {UserCacheService} from "core-components/user/user-cache.service";
import {IEditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler.interface";
import {CommentService} from "core-components/wp-activity/comment-service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'user-activity',
  templateUrl: './user-activity.component.html'
})
export class UserActivityComponent implements IEditFieldHandler, OnInit, AfterViewInit {
  @Input() public workPackage:WorkPackageResource;
  @Input() public activity:any;
  @Input() public activityNo:number;
  @Input() public activityLabel:string;
  @Input() public isInitial:boolean;

  public handler = this;
  public inEdit = false;
  public inEditMode = false;
  public userCanEdit = false;
  public userCanQuote = false;

  public userId:string | number;
  public userName:string;
  public userAvatar:string;
  public userActive:boolean;
  public userPath:string | null;
  public userLabel:string;
  public fieldLabel:string;
  public details:any[] = [];
  public isComment:boolean;

  public field:WorkPackageCommentField;
  public focused = false;

  public text = {
    label_created_on: this.I18n.t('js.label_created_on'),
    label_updated_on: this.I18n.t('js.label_updated_on'),
    quote_comment: this.I18n.t('js.label_quote_comment'),
    edit_comment: this.I18n.t('js.label_edit_comment'),
  };

  public accessibilityModeEnabled = this.ConfigurationService.accessibilityModeEnabled();
  private $element:JQuery;

  constructor(readonly elementRef:ElementRef,
              readonly PathHelper:PathHelperService,
              readonly wpLinkedActivities:WorkPackagesActivityService,
              readonly commentService:CommentService,
              readonly wpCacheService:WorkPackageCacheService,
              readonly ConfigurationService:ConfigurationService,
              readonly userCacheService:UserCacheService,
              readonly I18n:I18nService) {
  }

  public ngOnInit() {
    this.isComment = this.activity._type === 'Activity::Comment';
    this.$element = jQuery(this.elementRef.nativeElement);
    this.reset();
    this.userCanEdit = !!this.activity.update;
    this.userCanQuote = !!this.workPackage.addComment;

    if (this.postedComment) {
      this.fieldLabel = this.I18n.t('js.label_activity_with_comment_no', {
        activityNo: this.activityNo
      });
    } else {
      this.fieldLabel = this.I18n.t('js.label_activity_no', {activityNo: this.activityNo});
    }

    this.$element.bind('focusin', this.focus.bind(this));
    this.$element.bind('focusout', this.blur.bind(this));

    _.each(this.activity.details, (detail:any) => {
      this.details.push(detail.html);
    });

    this.userCacheService
      .require(this.activity.user.idFromLink)
      .then((user:UserResource) => {
        this.userId = user.id;
        this.userName = user.name;
        this.userAvatar = user.avatar;
        this.userActive = user.isActive;
        this.userPath = user.showUser.href;
        this.userLabel = this.I18n.t('js.label_author', {user: this.userName});
      });
  }

  public shouldHideIcons():boolean {
    return !(this.isComment && (this.focussing() || this.accessibilityModeEnabled));
  }

  public get postedComment() {
    return this.activity.comment.html;
  }

  public ngAfterViewInit() {
    if (window.location.hash === 'activity-' + this.activityNo) {
      this.elementRef.nativeElement.scrollIntoView(true);
    }
  }

  public reset(withText?:string) {
    this.field = new WorkPackageCommentField(this.workPackage);
    this.field.initializeFieldValue(withText);
  }

  public handleUserSubmit() {
    this.field.onSubmit();
    if (this.field.isBusy || this.field.isEmpty()) {
      return Promise.resolve();
    }
    return this.updateComment();
  }

  public handleUserCancel() {
    this.deactivate(true);
  }

  public get active() {
    return this.inEdit;
  }

  public editComment() {
    this.inEdit = true;
    this.reset(this.activity.comment.raw);
  }

  public quoteComment() {
    this.commentService.quoteEvents.next(this.quotedText(this.activity.comment.raw));
  }

  public updateComment() {
    return this.commentService.updateComment(this.activity, this.field.rawValue || '')
      .then(() => {
        this.wpLinkedActivities.require(this.workPackage, true);
        this.wpCacheService.updateWorkPackage(this.workPackage);
        this.deactivate(true);
      });
  }

  public focusEditIcon() {
    // Find the according edit icon and focus it
    jQuery('.edit-activity--' + this.activityNo + ' a').focus();
  }

  public focus() {
    setTimeout(() => this.focused = true);
  }

  public blur() {
    setTimeout(() => this.focused = false);
  }

  public focussing() {
    return this.focused;
  }

  public quotedText(rawComment:string) {
    var quoted = rawComment.split('\n')
      .map(function(line:string) {
        return '\n> ' + line;
      })
      .join('');
    return this.userName + ' wrote:\n' + quoted;
  }

  public get htmlId() {
    return `user_activity_edit_field_${this.activityNo}`;
  }

  public get project() {
    return this.workPackage.project;
  }

  deactivate(focus:boolean):void {
    this.inEdit = false;

    if (focus) {

      this.focusEditIcon();
    }
  }

  handleUserKeydown(event:JQueryEventObject, onlyCancel?:boolean):void {
  }

  isChanged():boolean {
    return false;
  }

  stopPropagation(evt:JQueryEventObject):boolean {
    return false;
  }
}
