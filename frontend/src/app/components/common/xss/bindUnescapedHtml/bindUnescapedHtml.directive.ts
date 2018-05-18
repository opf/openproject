// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
// Heavily borrows from foundation-apps ModalFactory. Copyright (c) 2014 ZURB, inc.
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

import ExpressionService from "../expression.service";
function bindUnescapedHtml(ExpressionService:ExpressionService, $sce:ng.ISCEService) {
  var foundationModalLink = function (scope:any) {
    scope.$watch('value', (value:any) => {
      scope.escapedValue = '';

      if (value) {
        value = ExpressionService.unescape(value.toString());
        scope.escapedValue = $sce.trustAsHtml(value);
      }
    });
  };

  return {
    restrict: 'A',
    template: '<span class="read-value--html" ng-bind-html="escapedValue"></span>',
    scope: {
      value: '=bindUnescapedHtml',
    },
    link: foundationModalLink,
  };
}

angular
  .module('openproject.uiComponents')
  .directive('bindUnescapedHtml', bindUnescapedHtml);
