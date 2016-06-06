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

import {wpDirectivesModule} from "../../../angular-modules";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";

export class RelationsPanelController {
  public workPackage:WorkPackageResource;

  constructor($q,
              $scope,
              RELATION_TYPES,
              RELATION_IDENTIFIERS,
              WorkPackagesHelper,
              CommonRelationsHandler,
              ChildrenRelationsHandler,
              ParentRelationsHandler) {

    $q.all(WorkPackagesHelper.getParent(this.workPackage)).then(function (parents) {
      $scope.wpParent = new ParentRelationsHandler(this.workPackage, parents, 'parent');
    });

    $q.all(WorkPackagesHelper.getChildren(this.workPackage)).then(function (children) {
      $scope.wpChildren = new ChildrenRelationsHandler(this.workPackage, children);
    });

    var relationTypeIterator = (key) => {
      $q.all(WorkPackagesHelper.getRelationsOfType(this.workPackage, RELATION_TYPES[key]))
        .then(relations => {
          $scope[key] = new CommonRelationsHandler(
            this.workPackage, relations, RELATION_IDENTIFIERS[key]);
        });
    };

    for (var key in RELATION_TYPES) {
      if (RELATION_TYPES.hasOwnProperty(key)) {
        relationTypeIterator(key);
      }
    }
  }
}

function relationsPanelDirective() {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-panels/relations-panel/relations-panel.directive.html',

    scope: {
      workPackage: '='
    },

    controller: RelationsPanelController,
    controllerAs: '$ctrl',
    bindToController: true
  };
}

wpDirectivesModule.directive('relationsPanel', relationsPanelDirective);
