// -- copyright
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
// ++

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {ErrorResource} from 'core-app/modules/hal/resources/error-resource';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {CommentService} from "core-components/wp-activity/comment-service";
import {
  Component,
  ContentChild,
  ElementRef,
  Inject, Injector,
  Input,
  OnDestroy,
  OnInit,
  TemplateRef,
  ViewChild
} from "@angular/core";
import {ConfigurationService} from "core-app/modules/common/config/configuration.service";

import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageChangeset} from "core-components/wp-edit-form/work-package-changeset";
import {WorkPackageCommentFieldHandler} from "core-components/work-packages/work-package-comment/work-package-comment-field-handler";

@Component({
  selector: 'work-package-comment',
  templateUrl: './work-package-comment.component.html'
})
export class WorkPackageCommentComponent extends WorkPackageCommentFieldHandler implements OnInit, OnDestroy {
  @Input() public workPackage:WorkPackageResource;

  @ContentChild(TemplateRef) template:TemplateRef<any>;
  @ViewChild('commentContainer') public commentContainer:ElementRef;

  public text = {
    editTitle: this.I18n.t('js.label_add_comment_title'),
    addComment: this.I18n.t('js.label_add_comment'),
    cancelTitle: this.I18n.t('js.label_cancel_comment'),
    placeholder: this.I18n.t('js.label_add_comment_title')
  };
  public fieldLabel:string = this.text.editTitle;

  public inFlight = false;
  public canAddComment:boolean;
  public showAbove:boolean;
  public changeset:WorkPackageChangeset;

  constructor(protected elementRef:ElementRef,
              protected injector:Injector,
              protected commentService:CommentService,
              protected wpLinkedActivities:WorkPackagesActivityService,
              protected ConfigurationService:ConfigurationService,
              protected loadingIndicator:LoadingIndicatorService,
              protected wpCacheService:WorkPackageCacheService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected NotificationsService:NotificationsService,
              protected I18n:I18nService) {
    super(elementRef, injector);
  }

  public ngOnInit() {
    super.ngOnInit();

    this.canAddComment = !!this.workPackage.addComment;
    this.showAbove = this.ConfigurationService.commentsSortedInDescendingOrder();

    this.commentService.quoteEvents
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((quote:string) => {
        this.activate(quote);
        this.commentContainer.nativeElement.scrollIntoView();
      });
  }

  // Open the field when its closed and relay drag & drop events to it.
  public startDragOverActivation(event:JQueryEventObject) {
    if (this.active) {
      return true;
    }

    this.activate();

    event.preventDefault();
    return false;
  }


  public ngOnDestroy() {
    // Nothing to do.
  }

  public get htmlId() {
    return 'wp-comment-field';
  }

  public activate(withText?:string) {
    super.activate(withText);

    if (!this.showAbove) {
      this.scrollToBottom();
    }
  }

  public deactivate(focus:boolean) {
    focus && this.focus();
    this.inEdit = false;
  }

  public async handleUserSubmit() {
    if (this.inFlight || !this.rawComment) {
      return Promise.resolve();
    }

    this.inFlight = true;
    await this.onSubmit();
    let indicator = this.loadingIndicator.wpDetails;
    return indicator.promise = this.commentService.createComment(this.workPackage, this.commentValue)
      .then(() => {
        this.inEdit = false;
        this.NotificationsService.addSuccess(this.I18n.t('js.work_packages.comment_added'));

        this.wpLinkedActivities.require(this.workPackage, true);
        this.wpCacheService.updateWorkPackage(this.workPackage);
        this.inFlight = false;
        this.focus();
      })
      .catch((error:any) => {
        this.inFlight = false;
        if (error instanceof ErrorResource) {
          this.wpNotificationsService.showError(error, this.workPackage);
        }
        else {
          this.NotificationsService.addError(this.I18n.t('js.work_packages.comment_send_failed'));
        }
      });
  }

  scrollToBottom():void {
    const scrollableContainer = jQuery(this.elementRef.nativeElement).scrollParent()[0];
    if (scrollableContainer) {
      setTimeout(() => { scrollableContainer.scrollTop = scrollableContainer.scrollHeight; }, 400);
    }
  }
}
