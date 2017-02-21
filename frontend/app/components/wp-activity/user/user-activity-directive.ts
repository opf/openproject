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

angular
  .module('openproject.workPackages.activities')
  .directive('userActivity', userActivity);

function userActivity($uiViewScroll:any,
                      $timeout:ng.ITimeoutService,
                      $location:ng.ILocationService,
                      $sce:ng.ISCEService,
                      I18n:op.I18n,
                      PathHelper:any,
                      ActivityService:any,
                      wpCacheService:WorkPackageCacheService,
                      ConfigurationService:any,
                      AutoCompleteHelper:any,
                      TextileService:any) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/activities/_user.html',
    scope: {
      workPackage: '=',
      activity: '=',
      activityNo: '=',
      activityLabel: '=',
      isInitial: '='
    },
    link: function (scope:any, element:ng.IAugmentedJQuery) {
      scope.$watch('inEdit', function (newVal:boolean, oldVal:boolean) {
        var textarea = element.find('.edit-comment-text');
        if (newVal) {
          $timeout(function () {
            AutoCompleteHelper.enableTextareaAutoCompletion(textarea);
            textarea.focus();
            textarea.on('keydown keypress', function (e) {
              if (e.keyCode === 27) {
                scope.inEdit = false;
              }
            });
          });
        } else {
          textarea.off('keydown keypress');
        }
      });

      scope.I18n = I18n;
      scope.inEdit = false;
      scope.inPreview = false;
      scope.userCanEdit = !!scope.activity.update;
      scope.userCanQuote = !!scope.workPackage.addComment;
      scope.accessibilityModeEnabled = ConfigurationService.accessibilityModeEnabled();

      scope.activity.user.$load().then((user:UserResource) => {
        scope.userId = user.id;
        scope.userName = user.name;
        scope.userAvatar = user.avatar;
        scope.userActive = user.isActive;
        scope.userPath = user.showUser.href;
        scope.userLabel = I18n.t('js.label_author', {user: scope.userName});
      });

      scope.postedComment = $sce.trustAsHtml(scope.activity.comment.html);
      if (scope.postedComment) {
        scope.activityLabelWithComment = I18n.t('js.label_activity_with_comment_no', {
          activityNo: scope.activityNo
        });
      }
      scope.details = [];

      angular.forEach(scope.activity.details, function (this:any[], detail) {
        this.push($sce.trustAsHtml(detail.html));
      }, scope.details);

      $timeout(function () {
        if ($location.hash() === 'activity-' + scope.activityNo) {
          $uiViewScroll(element);
        }
      });

      scope.editComment = function () {
        scope.activity.editedComment = scope.activity.comment.raw;
        scope.inEdit = true;
      };

      scope.cancelEdit = function () {
        scope.inEdit = false;
        scope.focusEditIcon();
      };

      scope.quoteComment = function () {
        scope.$emit(
          'workPackage.comment.quoteThis',
          quotedText(scope.activity.comment.raw)
        );
      };

      scope.updateComment = function () {
        ActivityService.updateComment(scope.activity, scope.activity.editedComment || '').then(function () {
          scope.workPackage.updateActivities();
          scope.inEdit = false;
        });
        scope.focusEditIcon();
      };

      scope.focusEditIcon = function () {
        // Find the according edit icon and focus it
        jQuery('.edit-activity--' + scope.activityNo + ' a').focus();
      }

      scope.toggleCommentPreview = function () {
        scope.isPreview = !scope.isPreview;
        scope.previewHtml = '';
        if (scope.isPreview) {
          TextileService.renderWithWorkPackageContext(
            scope.workPackage,
            scope.activity.editedComment
          ).then(function (r:any) {
            scope.previewHtml = $sce.trustAsHtml(r.data);
          }, function () {
            scope.isPreview = false;
          });
        }
      };

      var focused = false;
      scope.focus = function () {
        $timeout(function () {
          focused = true;
        });
      };

      scope.blur = function () {
        $timeout(function () {
          focused = false;
        });
      };

      scope.focussing = function () {
        return focused;
      };

      element.bind('focusin', scope.focus);
      element.bind('focusout', scope.blur);

      function quotedText(rawComment:string) {
        var quoted = rawComment.split("\n")
          .map(function (line:string) {
            return "\n> " + line;
          })
          .join('');
        return scope.userName + " wrote:" + quoted;
      }
    }
  };
}
