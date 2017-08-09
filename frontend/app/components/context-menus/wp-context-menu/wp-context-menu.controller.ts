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

import {WorkPackageTableSelection} from '../../wp-fast-table/state/wp-table-selection.service';
import {ContextMenuService} from '../context-menu.service';
import {WorkPackageTable} from "../../wp-fast-table/wp-fast-table";
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageRelationsHierarchyService} from "../../wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {States} from '../../states.service';

function wpContextMenuController($scope:any,
                                 $rootScope:ng.IRootScopeService,
                                 $state:ng.ui.IStateService,
                                 states:States,
                                 WorkPackageContextMenuHelper:any,
                                 WorkPackageService:any,
                                 wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
                                 contextMenu:ContextMenuService,
                                 I18n:op.I18n,
                                 $window:ng.IWindowService,
                                 wpTableSelection:WorkPackageTableSelection,
                                 PERMITTED_CONTEXT_MENU_ACTIONS:any) {

  $scope.I18n = I18n;

  const wpId = $scope.workPackageId;
  const workPackage = states.workPackages.get(wpId).value!;
  if (!wpTableSelection.isSelected(wpId)) {
    wpTableSelection.setSelection(wpId, $scope.rowIndex);
  }

  $scope.permittedActions = WorkPackageContextMenuHelper.getPermittedActions(getSelectedWorkPackages(), PERMITTED_CONTEXT_MENU_ACTIONS);

  $scope.isDetailsViewLinkPresent = function () {
    return !!angular.element('#work-package-context-menu li.open').length;
  };

  $scope.triggerContextMenuAction = function (action:any, link:any) {
    switch (action) {
      case 'delete':
        deleteSelectedWorkPackages();
        break;

      case 'edit':
        editSelectedWorkPackages(link);
        break;

      case 'copy':
        copySelectedWorkPackages(link);
        break;

      case 'relation-precedes':
        $scope.table.timelineController.startAddRelationPredecessor(workPackage);
        break;

      case 'relation-follows':
        $scope.table.timelineController.startAddRelationFollower(workPackage);
        break;

      case 'relation-new-child':
        wpRelationsHierarchyService.addNewChildWp(workPackage);
        break;

      default:
        $window.location.href = link;
        break;
    }
  };

  $scope.cancelInlineCreate = function (index:number, row:any) {
    $rootScope.$emit('inlineWorkPackageCreateCancelled', index, row);
    emitClosingEvents();
  };

  function emitClosingEvents() {
    contextMenu.close();
  }

  function deleteSelectedWorkPackages() {
    let ids = wpTableSelection.getSelectedWorkPackageIds();

    WorkPackageService.performBulkDelete(ids, true);
  }

  function editSelectedWorkPackages(link:any) {
    var selected = getSelectedWorkPackages();

    if (selected.length > 1) {
      $window.location.href = link;
      return;
    }
  }

  function copySelectedWorkPackages(link:any) {
    var selected = getSelectedWorkPackages();

    if (selected.length > 1) {
      $window.location.href = link;
      return;
    }

    var params = {
      copiedFromWorkPackageId: selected[0].id
    };

    $state.transitionTo('work-packages.list.copy', params);
  }

  function getSelectedWorkPackages() {
    let selectedWorkPackages = wpTableSelection.getSelectedWorkPackages();

    if (selectedWorkPackages.length === 0) {
      return [workPackage];
    }

    if (selectedWorkPackages.indexOf(workPackage) === -1) {
      selectedWorkPackages.push(workPackage);
    }

    return selectedWorkPackages;
  }
}

angular
  .module('openproject.workPackages')
  .controller('WorkPackageContextMenuController', wpContextMenuController);
