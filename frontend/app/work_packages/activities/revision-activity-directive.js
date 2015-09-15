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

module.exports = function($compile,
    $sce,
    I18n,
    PathHelper,
    ActivityService,
    UsersHelper) {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/activities/_revision.html',
    scope: {
      workPackage: '=',
      activity: '=',
      activityNo: '=',
    },
    link: function(scope, element) {
      scope.I18n = I18n;
      if (scope.activity.links.author === undefined) {
        scope.userName = scope.activity.props.authorName;
      } else {
        scope.userPath = PathHelper.staticUserPath;
        scope.activity.links.author.fetch().then(function(user) {
          scope.userId = user.props.id;
          scope.userName = user.props.name;
          scope.userAvatar = user.props.avatar;
          scope.userActive = UsersHelper.isActive(user);
        });
      }

      scope.project = scope.workPackage.embedded.project;
      scope.revision = scope.activity.props.identifier;
      scope.formattedRevision = scope.activity.props.formattedIdentifier;
      scope.revisionPath = scope.activity.links.showRevision.href;
      scope.message = $sce.trustAsHtml(scope.activity.props.message.html);

      var date = '<op-date-time date-time-value="activity.props.createdAt"/></op-date-time>';
      var link = [
        '<a ng-href="{{ revisionPath }}" title="{{ revision }}">',
        '{{ I18n.t("js.label_committed_link", { revision_identifier: formattedRevision }) }}',
        '</a>'
      ].join('');

      scope.combinedRevisionLink = I18n.t("js.label_committed_at",
        {
          committed_revision_link: link,
          date: date
        });

      scope.$watch('combinedRevisionLink', function(html) {
        var span = angular.element(html),
          link = element.find('.revision-activity--revision-link');

        link.append(span);
        $compile(link.contents())(scope);
      });

    }
  };
};
