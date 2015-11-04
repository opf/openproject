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

angular
  .module('openproject.inplace-edit')
  .directive('inplaceDisplayUser', inplaceDisplayUser);

function inplaceDisplayUser() {
  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    require: '^inplaceEditorDisplayPane',
    templateUrl: '/components/inplace-edit/directives/field-display/display-user/' +
      'display-user.directive.html',

    controller: InplaceDisplayUserController,
    controllerAs: 'customEditorController',

    link: function(scope, element, attrs, inplaceEditorDisplayPane) {
      scope.inplaceEditorDisplayPane = inplaceEditorDisplayPane;

      scope.$watch('field.text', function(value) {
        scope.customEditorController.initializeUserWith(value);
      });
    }
  };
}

function InplaceDisplayUserController($scope, PathHelper) {
  var getUserName = function(user) {
    if (user && user.props) {
      return user.props.name;
    }
  };

  var getIsGroup = function(user) {
    return user.props.subtype === 'Group';
  };

  var getHref = function(user) {
    var id = user.props.id;

    return PathHelper.staticUserPath(id);
  };

  var getAvatar = function(user) {
    return user.props.avatar;
  };

  var getRole = function(userData) {
    return userData.props.role;
  };

  this.initializeUserWith = function(userData) {
    $scope.user = userData;

    if (userData) {
      $scope.user.name = getUserName(userData);
      $scope.user.isGroup = getIsGroup(userData);
      $scope.user.href = getHref(userData);
      $scope.user.avatar = getAvatar(userData);
      $scope.user.role = getRole(userData);
    }
  };
}

InplaceDisplayUserController.$inject = ['$scope', 'PathHelper'];
