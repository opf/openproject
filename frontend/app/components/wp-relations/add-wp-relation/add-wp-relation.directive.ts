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

import {wpTabsModule} from "../../../angular-modules";
import {WorkPackageRelationsController} from "../wp-relations.directive";

declare const URI;

function addWpRelationDirective($http, PathHelper, I18n) {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-relations/add-wp-relation/add-wp-relation.directive.html',
    require: '^wpRelations',
    
    link: function (scope, element, attrs, relationsCtrl:WorkPackageRelationsController) {
      scope.text = {
        uiSelectTitle: I18n.t('js.field_value_enter_prompt', {
          field: I18n.t('js.relation_labels.' + relationsCtrl.handler.relationsId)
        })
      };
      scope.relationToAddId = null;
      scope.autocompleteWorkPackages = function (term) {
        if (!term) return;

        var params = {
          q: term,
          scope: 'relatable',
          escape: false,
          id: relationsCtrl.handler.workPackage.id,
          project_id: relationsCtrl.handler.workPackage.project.id
        };

        return $http({
            method: 'GET',
            url: URI(PathHelper.workPackageJsonAutoCompletePath()).search(params).toString()
          }
        ).then(function (response) {
          scope.options = response.data;
        });
      }
    }
  };
}

wpTabsModule.directive('addWpRelation', addWpRelationDirective);
