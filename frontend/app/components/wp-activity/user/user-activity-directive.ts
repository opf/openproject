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

import {UserResource} from '../../api/api-v3/hal-resources/user-resource.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {TextileService} from './../../common/textile/textile-service';
import {ActivityService} from './../activity-service';
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';
import {ConfigurationService} from 'core-components/common/config/configuration.service';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';
import {ActivityEntryInfo} from 'core-components/wp-single-view-tabs/activity-panel/activity-entry-info';
import {HalResource} from 'core-components/api/api-v3/hal-resources/hal-resource.service';
import {WorkPackageCommentField} from 'core-components/work-packages/work-package-comment/wp-comment-field.module';

export class UserActivityController {
  public workPackage:WorkPackageResourceInterface;
  public activity:HalResource;
  public activityNo:string;
  public activityLabel:string;
  public isInitial:boolean;

  public inEdit = false;
  public inEditMode = false;
  public userCanEdit= false;
  public userCanQuote = false;

  public userId:string|number;
  public userName:string;
  public userAvatar:string;
  public userActive:boolean;
  public userPath:string|null;
  public userLabel:string;
  public postedComment:string;
  public activityLabelWithComment?:string;
  public details:any[] = [];

  public field:WorkPackageCommentField;
  public focused = false;

  public accessibilityModeEnabled = this.ConfigurationService.accessibilityModeEnabled();

  constructor(readonly $uiViewScroll:any,
              readonly $scope:ng.IScope,
              readonly $timeout:ng.ITimeoutService,
              readonly $q:ng.IQService,
              readonly $element:ng.IAugmentedJQuery,
              readonly $location:ng.ILocationService,
              readonly $sce:ng.ISCEService,
              readonly I18n:op.I18n,
              readonly PathHelper:PathHelperService,
              readonly wpActivityService:ActivityService,
              readonly wpCacheService:WorkPackageCacheService,
              readonly ConfigurationService:ConfigurationService,
              readonly AutoCompleteHelper:any,
              readonly textileService:TextileService) {
  }

  public $onInit() {
    this.resetField();
    this.userCanEdit = !!this.activity.update;
    this.userCanQuote = !!this.workPackage.addComment;
    this.postedComment = this.$sce.trustAsHtml(this.activity.comment.html);

    if (this.postedComment) {
      this.activityLabelWithComment = I18n.t('js.label_activity_with_comment_no', {
        activityNo: this.activityNo
      });
    }

    this.$element.bind('focusin', this.focus.bind(this));
    this.$element.bind('focusout', this.blur.bind(this));

    angular.forEach(this.activity.details,  (detail:any) => {
      this.details.push(this.$sce.trustAsHtml(detail.html));
    });

    if (this.$location.hash() === 'activity-' + this.activityNo) {
      this.$uiViewScroll(this.$element);
    }

    this.activity.user.$load().then((user:UserResource) => {
      this.userId = user.id;
      this.userName = user.name;
      this.userAvatar = user.avatar;
      this.userActive = user.isActive;
      this.userPath = user.showUser.href;
      this.userLabel = this.I18n.t('js.label_author', {user: this.userName});
    });
  }

  public resetField(withText?:string) {
    this.field = new WorkPackageCommentField(this.workPackage, I18n);
    this.field.initializeFieldValue(withText);
  }

  public handleUserSubmit() {
    this.field.onSubmit();
    if (this.field.isBusy || this.field.isEmpty()) {
      return;
    }
    this.updateComment();
  }

  public handleUserCancel() {
    this.inEdit = false;
    this.focusEditIcon();
  }

  public get active() {
    return this.inEdit;
  }

  public editComment() {
    this.inEdit = true;

    this.resetField(this.activity.comment.raw);
    this.waitForField()
      .then(() => {
        this.field.$onInit(this.$element);
      });
  }

  // Ensure the nested ng-include has rendered
  private waitForField():Promise<JQuery> {
    const deferred = this.$q.defer<JQuery>();

    const interval = setInterval(() => {
      const container = this.$element.find('.op-ckeditor-element');

      if (container.length > 0) {
        clearInterval(interval);
        deferred.resolve(container);
      }
    }, 100);

    return deferred.promise;
  }

  public quoteComment() {
    this.wpActivityService.quoteEvents.putValue(this.quotedText(this.activity.comment.raw));
  }

  public updateComment() {
    this.wpActivityService.updateComment(this.activity, this.field.rawValue || '')
      .then(() => {
      this.workPackage.updateActivities();
      this.inEdit = false;
    });
    this.focusEditIcon();
  }

  public focusEditIcon() {
    // Find the according edit icon and focus it
    jQuery('.edit-activity--' + this.activityNo + ' a').focus();
  }

  public focus() {
    this.$timeout(() => this.focused = true);
  }

  public blur() {
    this.$timeout(() => this.focused = false);
  }

  public focussing() {
    return this.focused;
  }

  public quotedText(rawComment:string) {
    var quoted = rawComment.split('\n')
      .map(function (line:string) {
        return '\n> ' + line;
      })
      .join('');
    return this.userName + ' wrote:\n' + quoted;
  }
}

angular
  .module('openproject.workPackages.activities')
  .directive('userActivity', function() {
    return {
      restrict: 'E',
      templateUrl: '/templates/work_packages/activities/_user.html',
      scope: {
        workPackage: '=',
        activity: '=',
        activityNo: '=',
        activityLabel: '=',
        isInitial: '='
      },
      controller: UserActivityController,
      bindToController: true,
      controllerAs: 'vm'
    };
  });


