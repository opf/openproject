//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
angular.module('openproject.uiComponents')

.directive('workPackageRelations', [
    'I18n',
    'PathHelper',
    '$timeout',
    function(I18n, PathHelper, $timeout) {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      title: '@',
      workPackage: '=',
      relations: '=',
      relationIdentifier: '=',
      btnTitle: '@buttonTitle',
      btnIcon: '@buttonIcon',
      isSingletonRelation: '@singletonRelation'
    },
    templateUrl: '/templates/work_packages/tabs/_work_package_relations.html',
    link: function(scope, element, attrs) {
      scope.I18n = I18n;

      var setExpandState = function() {
        scope.expand = scope.relations && scope.relations.length > 0;
      };

      scope.$watch('relations', function() {
        setExpandState();
      });

      scope.addRelation = function(toId, relationType) {

      }

      scope.collapseStateIcon = function(collapsed) {
        var iconClass = 'icon-arrow-right5-';

        if (collapsed) {
          iconClass += '3';
        } else {
          iconClass += '2';
        }

        return iconClass;
      }

      // Massive hack alert - Using old prototype autocomplete ///////////
      $timeout(function(){
        var url = "/work_packages/auto_complete?escape=false&id=" + scope.workPackage.props.id + "&project_id=" + scope.workPackage.props.projectId;
        new Ajax.Autocompleter('relation_to_id-' + scope.relationIdentifier,
                               'related_issue_candidates-' + scope.relationIdentifier,
                               url,
                               { minChars: 1,
                                 frequency: 0.5,
                                 paramName: 'q',
                                 updateElement: function(value) {
                                   document.getElementById('relation_to_id-' + scope.relationIdentifier).value = value.id;
                                 },
                                 parameters: 'scope=all'
                                 });
      });
      ////////////////////////////////////////////////////////////////////
    }
  };
}]);
