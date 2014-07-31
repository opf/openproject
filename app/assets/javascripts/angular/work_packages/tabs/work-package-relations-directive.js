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
angular.module('openproject.workPackages.tabs')

.directive('workPackageRelations', [
    'I18n',
    'PathHelper',
    'WorkPackageService',
    'WorkPackagesHelper',
    'PathHelper',
    'ApiHelper',
    '$timeout',
    function(I18n, PathHelper, WorkPackageService, WorkPackagesHelper, PathHelper, ApiHelper, $timeout) {
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
      scope.canAddRelation = !!scope.workPackage.links.addRelation;
      scope.$watch('relations', function(newVal, oldVal) {
        if(newVal) {
          scope.visibleRelations = newVal.filter(function(relation){
            return !!WorkPackagesHelper.getRelatedWorkPackageLink(scope.workPackage, relation);
          });
        }
      });

      var setExpandState = function() {
        scope.expand = scope.visibleRelations && scope.visibleRelations.length > 0;
      };

      scope.$watch('visibleRelations', function() {
        setExpandState();
        if(scope.visibleRelations) {
          scope.relationsCount = scope.visibleRelations.length || 0;
        }
      });

      scope.$watch('expand', function(newVal, oldVal) {
        scope.stateClass = WorkPackagesHelper.collapseStateIcon(!newVal);
      });

      scope.addRelation = function() {
        var inputElement = angular.element('#relation_to_id-' + scope.relationIdentifier);
        var toId = inputElement.val();
        WorkPackageService.addWorkPackageRelation(scope.workPackage, toId, scope.relationIdentifier).then(function(relation) {
            inputElement.val('');
            scope.$emit('workPackageRefreshRequired', '');
        }, function(error) {
          ApiHelper.handleError(scope, error);
        });
      };

      // Massive hack alert - Using old prototype autocomplete ///////////
      if(scope.canAddRelation) {
        $timeout(function(){
          var url = PathHelper.workPackageAutoCompletePath(scope.workPackage.props.projectId, scope.workPackage.props.id);
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
      }
      ////////////////////////////////////////////////////////////////////
    }
  };
}]);
