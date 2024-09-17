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

import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ContentChild,
  ElementRef,
  Injector,
  Input,
  OnDestroy,
  OnInit,
  TemplateRef,
  ViewChild,
} from '@angular/core';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageCommentFieldHandler } from 'core-app/features/work-packages/components/work-package-comment/work-package-comment-field-handler';
import { CommentService } from 'core-app/features/work-packages/components/wp-activity/comment-service';
import { WorkPackagesActivityService } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  filter,
  take,
} from 'rxjs/operators';

@Component({
  selector: 'work-package-comment',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './work-package-comment.component.html',
})
export class WorkPackageCommentComponent extends WorkPackageCommentFieldHandler implements OnInit, OnDestroy {
  @Input() public workPackage:WorkPackageResource;

  @ContentChild(TemplateRef) template:TemplateRef<any>;

  @ViewChild('commentContainer') public commentContainer:ElementRef;

  public text = {
    editTitle: this.I18n.t('js.label_add_comment_title'),
    addComment: this.I18n.t('js.label_add_comment'),
    cancelTitle: this.I18n.t('js.label_cancel_comment'),
    placeholder: this.I18n.t('js.label_add_comment_title'),
  };

  public fieldLabel:string = this.text.editTitle;

  public inFlight = false;

  public canAddComment:boolean;

  public showAbove:boolean;

  public primerizedActivitiesEnabled:boolean;

  public turboFrameSrc:string;

  public htmlId = 'wp-comment-field';

  constructor(protected elementRef:ElementRef,
    protected injector:Injector,
    protected commentService:CommentService,
    protected wpLinkedActivities:WorkPackagesActivityService,
    protected configurationService:ConfigurationService,
    protected loadingIndicator:LoadingIndicatorService,
    protected apiV3Service:ApiV3Service,
    protected workPackageNotificationService:WorkPackageNotificationService,
    protected toastService:ToastService,
    protected cdRef:ChangeDetectorRef,
    protected I18n:I18nService,
    readonly PathHelper:PathHelperService,
  ) {
    super(elementRef, injector);
  }

  public ngOnInit():void {
    super.ngOnInit();

    this.canAddComment = !!this.workPackage.addComment;
    this.showAbove = this.configurationService.commentsSortedInDescendingOrder();
    this.primerizedActivitiesEnabled = this.configurationService.activeFeatureFlags.includes('primerizedWorkPackageActivities');
    this.turboFrameSrc = `${this.PathHelper.staticBase}/work_packages/${this.workPackage.id}/activities`;

    this.commentService.draft$
      .pipe(
        this.untilDestroyed(),
        take(1),
        filter((val) => !!val),
      )
      .subscribe((draft:string) => {
        this.activate(draft);
      });

    this.commentService.quoteEvents$
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((quote:string) => {
        this.activate(quote);
        this.commentContainer.nativeElement.scrollIntoView();
      });
  }

  public ngOnDestroy():void {
    super.ngOnDestroy();
    this.commentService.draft$.next(this.active ? this.rawComment : null);
  }

  // Open the field when its closed and relay drag & drop events to it.
  public startDragOverActivation(event:JQuery.TriggeredEvent):boolean {
    if (this.active) {
      return true;
    }

    this.activate();

    event.preventDefault();
    return false;
  }

  public activate(withText?:string):void {
    super.activate(withText);

    if (!this.showAbove) {
      this.scrollToBottom();
    }

    this.cdRef.detectChanges();
  }

  public deactivate(focus:boolean):void {
    focus && this.focus();
    this.active = false;
    this.cdRef.detectChanges();
  }

  public async handleUserSubmit():Promise<unknown> {
    if (this.inFlight || !this.rawComment) {
      return Promise.resolve();
    }

    this.inFlight = true;
    await this.onSubmit();
    const indicator = this.loadingIndicator.wpDetails;
    indicator.promise = this.commentService.createComment(this.workPackage, this.commentValue)
      .then(() => {
        this.active = false;
        this.toastService.addSuccess(this.I18n.t('js.work_packages.comment_added'));

        void this.wpLinkedActivities.require(this.workPackage, true);
        void this
          .apiV3Service
          .work_packages
          .id(this.workPackage.id!)
          .refresh();

        this.inFlight = false;
        this.deactivate(true);
      })
      .catch((error:any) => {
        this.inFlight = false;
        if (error instanceof HalError) {
          this.workPackageNotificationService.showError(error.resource, this.workPackage);
        } else {
          this.toastService.addError(this.I18n.t('js.work_packages.comment_send_failed'));
        }
      });

    return indicator.promise;
  }

  scrollToBottom():void {
    const scrollableContainer = jQuery(this.elementRef.nativeElement).scrollParent()[0];
    if (scrollableContainer) {
      setTimeout(() => {
        scrollableContainer.scrollTop = scrollableContainer.scrollHeight;
      }, 400);
    }
  }

  setErrors(newErrors:string[]):void {
    // interface
  }
}
