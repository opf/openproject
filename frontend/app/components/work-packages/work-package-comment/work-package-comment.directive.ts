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

import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCommentField} from './wp-comment-field.module';
import {ErrorResource} from '../../api/api-v3/hal-resources/error-resource.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {LoadingIndicatorService} from '../../common/loading-indicator/loading-indicator.service';

export class CommentFieldDirectiveController {
  public workPackage:WorkPackageResourceInterface;
  public field:WorkPackageCommentField;

  protected text:Object;

  protected editing = false;
  protected canAddComment:boolean;
  protected showAbove:boolean;
  protected _forceFocus:boolean = false;

  constructor(protected $scope:ng.IScope,
              protected $rootScope:ng.IRootScopeService,
              protected $timeout:ng.ITimeoutService,
              protected $q:ng.IQService,
              protected $element:ng.IAugmentedJQuery,
              protected ActivityService:any,
              protected ConfigurationService:any,
              protected loadingIndicator:LoadingIndicatorService,
              protected wpCacheService:WorkPackageCacheService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected NotificationsService:any,
              protected I18n:op.I18n) {

    this.text = {
      editTitle: I18n.t('js.label_add_comment_title'),
      addComment: I18n.t('js.label_add_comment'),
      cancelTitle: I18n.t('js.label_cancel_comment'),
      placeholder: I18n.t('js.label_add_comment_title')
    };

    this.field = new WorkPackageCommentField(this.workPackage, I18n);

    this.canAddComment = !!this.workPackage.addComment;
    this.showAbove = ConfigurationService.commentsSortedInDescendingOrder();

    $scope.$on('workPackage.comment.quoteThis', (evt, quote) => {
      this.field.initializeFieldValue(quote);
      this.editing = true;
      this.$element.find('.work-packages--activity--add-comment')[0].scrollIntoView();
    });
  }

  public get htmlId() {
    return 'wp-comment-field';
  }

  public get active() {
    return this.editing;
  }

  public get inEditMode() {
    return false;
  }

  public shouldFocus() {
    return this._forceFocus;
  }

  public activate(withText?:string) {
    this._forceFocus = true;
    this.field.initializeFieldValue(withText);
    this.editing = true;
    
    this.$timeout(() => this.$element.find('.wp-inline-edit--field').focus());
  }

  public handleUserSubmit() {
    if (this.field.isEmpty()) {
      return;
    }

    this.field.isBusy = true;
    let indicator = this.loadingIndicator.wpDetails;
    indicator.promise = this.ActivityService.createComment(this.workPackage, this.field.value)
      .then(() => {
        this.editing = false;
        this.NotificationsService.addSuccess(this.I18n.t('js.work_packages.comment_added'));

        this.workPackage.activities.$load(true).then(() => {
          this.wpCacheService.updateWorkPackage(this.workPackage);
        });
        this._forceFocus = true;
      })
      .catch((error:any) => {
        if (error instanceof ErrorResource) {
          this.wpNotificationsService.showError(error, this.workPackage);
        }
        else {
          this.NotificationsService.addError(this.I18n.t('js.work_packages.comment_send_failed'));
        }
      })
      .finally(() => {
        this.field.isBusy = false;
      });
  }

  public handleUserCancel() {
    this.editing = false;
    this.field.initializeFieldValue();
    this._forceFocus = true;
  }
}

function workPackageComment() {
  return {
    restrict: 'E',
    replace: true,
    transclude: true,
    templateUrl: '/components/work-packages/work-package-comment/work-package-comment.directive.html',
    scope: {
      workPackage: '=',
      activities: '='
    },

    controllerAs: 'vm',
    bindToController: true,
    controller: CommentFieldDirectiveController
  };
}

angular
  .module('openproject.workPackages.directives')
  .directive('workPackageComment', workPackageComment);
