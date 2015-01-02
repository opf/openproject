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

// TODO move to UI components
module.exports = function($timeout,
    I18n,
    ActivityService,
    ConfigurationService,
    AutoCompleteHelper) {
  return {
    restrict: 'E',
    replace: true,
    require: '^?exclusiveEdit',
    scope: {
      workPackage: '=',
      activities: '=',
      autocompletePath: '@'
    },
    templateUrl: '/templates/components/activity_comment.html',
    link: function(scope, element, attrs, exclusiveEditController) {
      exclusiveEditController.setCreator(scope);

      scope.title = I18n.t('js.label_add_comment_title');
      scope.buttonTitle = I18n.t('js.label_add_comment');
      scope.buttonCancel = I18n.t('js.button_cancel');
      scope.canAddComment = !!scope.workPackage.links.addComment;
      scope.activity = { comment: '' };

      scope.createComment = function() {
        var descending = ConfigurationService.commentsSortedInDescendingOrder();
        scope.processingComment = true;
        ActivityService.createComment(scope.workPackage, scope.activities, descending, scope.activity.comment)
          .then(function(response) {
            scope.activity.comment = '';
            scope.$emit('workPackageRefreshRequired', '');
            scope.processingComment = false;
            return response;
          });
      };

      $timeout(function() {
        AutoCompleteHelper.enableTextareaAutoCompletion(
          angular.element.find('textarea.add-comment-text')
        );
      });
    }
  };
};
