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

import {opWorkPackagesModule} from '../../../angular-modules';
import {ContextMenuService} from '../context-menu.service';
import {WorkPackageTableHierarchiesService} from '../../wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableSumService} from '../../wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableGroupByService} from '../../wp-fast-table/state/wp-table-group-by.service';
import {WorkPackagesListService} from '../../wp-list/wp-list.service';
import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service';
import {QueryFormResource} from '../../api/api-v3/hal-resources/query-form-resource.service';

import {States} from '../../states.service';

interface IMyScope extends ng.IScope {
  displaySumsLabel:string;
  displayHierarchies:boolean;
  displaySums:boolean;
  loading:boolean;
  saveQuery:Function;
  deleteQuery:Function;

  showSaveAsModal:Function;
  showShareModal:Function;
  showSettingsModal:Function;
  showExportModal:Function;
  showColumnsModal:Function;
  showGroupingModal:Function;
  showSortingModal:Function;
  toggleDisplaySums:Function;
  toggleHierarchies:Function;
  showSettingsModalInvalid:Function;
  showShareModalInvalid:Function;
  showExportModalInvalid:Function;
  deleteQueryInvalid:Function;
  showSaveModalInvalid:Function;
  saveQueryInvalid:Function;
}

function SettingsDropdownMenuController($scope:IMyScope,
                                        $window:ng.IWindowService,
                                        I18n:op.I18n,
                                        columnsModal:any,
                                        exportModal:any,
                                        saveModal:any,
                                        settingsModal:any,
                                        shareModal:any,
                                        sortingModal:any,
                                        groupingModal:any,
                                        contextMenu:ContextMenuService,
                                        wpTableHierarchies:WorkPackageTableHierarchiesService,
                                        wpTableSum:WorkPackageTableSumService,
                                        wpTableGroupBy:WorkPackageTableGroupByService,
                                        wpListService:WorkPackagesListService,
                                        states:States,
                                        AuthorisationService:any,
                                        NotificationsService:any) {

  let query:QueryResource;
  let form:QueryFormResource;

  $scope.text = {
    group_by_title: () => {
      if ($scope.displayHierarchies) {
        return I18n.t('js.work_packages.query.group_by_disabled_by_hierarchy');
      } else {
        return I18n.t('js.work_packages.query.hierarchy_mode');
      }
    },
    hierarchy_title: () => {
      if (wpTableGroupBy.current) {
        return I18n.t('js.work_packages.query.hierarchy_disabled_by_group_by', { column: wpTableGroupBy.current.id! });
      } else {
        return I18n.t('js.work_packages.query.group_by');
      }
    },
    loading: I18n.t('js.label_loading')
  };

  states
    .query
    .resource
    .values$()
    .takeUntil(states.table.stopAllSubscriptions)
    .subscribe(queryUpdate => {

    $scope.loading = true;

    query = queryUpdate;
  });

  states
    .query
    .form
    .values$()
    .takeUntil(states.table.stopAllSubscriptions)
    .subscribe(formUpdate => {

    form = formUpdate;

    $scope.displayHierarchies = wpTableHierarchies.isEnabled;
    $scope.displaySums = wpTableSum.isEnabled;
    $scope.isGrouped = wpTableGroupBy.isEnabled;

    $scope.displaySumsLabel = $scope.displaySums ? I18n.t('js.toolbar.settings.hide_sums')
                                                 : I18n.t('js.toolbar.settings.display_sums');


    if (query.results && query.results.customFields) {
      $scope.queryCustomFields = query.results.customFields;
    }

    $scope.loading = false;
  });

  $scope.saveQuery = function (event:JQueryEventObject) {
    event.stopPropagation();
    if (!query.id && allowQueryAction(event, 'updateImmediately')) {
      saveModal.activate();
    } else if (query.id && allowQueryAction(event, 'updateImmediately')) {
      wpListService.save();
    }

    closeAnyContextMenu();
  };

  $scope.deleteQuery = function (event:JQueryEventObject) {
    event.stopPropagation();
    if (allowQueryAction(event, 'delete') && deleteConfirmed()) {
      wpListService.delete();
    }

    closeAnyContextMenu();
  };

  // Modals
  $scope.showSaveAsModal = function (event:JQueryEventObject) {
    event.stopPropagation();
    if (allowFormAction(event, 'commit')) {
      showExistingQueryModal.call(saveModal, event);
      updateFocusInModal('save-query-name');
    }
  };

  $scope.showShareModal = function (event:JQueryEventObject) {
    event.stopPropagation();
    if (allowQueryAction(event, 'unstar') || allowQueryAction(event, 'star')) {
      showExistingQueryModal.call(shareModal, event);
      updateFocusInModal('show-public');
    }
  };

  $scope.showSettingsModal = function (event:JQueryEventObject) {
    event.stopPropagation();
    if (allowQueryAction(event, 'update')) {
      showExistingQueryModal.call(settingsModal, event);
      updateFocusInModal('query_name');
    }
  };

  $scope.showExportModal = function (event:JQueryEventObject) {
    event.stopPropagation();
    if (allowWorkPackageAction(event, 'representations')) {
      showModal.call(exportModal);
      setTimeout(function () {
        updateFocusInModal(jQuery("[id^='export-']").first().attr('id'));
      });
    }
  };

  $scope.showColumnsModal = function (event:JQueryEventObject) {
    event.stopPropagation();
    showModal.call(columnsModal);
    setTimeout(function () {
      updateFocusInModal(jQuery("[id^='column-']").first().attr('id'));
    });
  };

  $scope.showGroupingModal = function (event:JQueryEventObject) {
    event.stopPropagation();
    showModal.call(groupingModal);
    updateFocusInModal('selected_columns_new');
  };

  $scope.showSortingModal = function (event:JQueryEventObject) {
    event.stopPropagation();
    showModal.call(sortingModal);
    updateFocusInModal('modal-sorting-attribute-0');
  };

  $scope.toggleHierarchies = function () {
    const isEnabled = wpTableHierarchies.isEnabled;
    wpTableHierarchies.setEnabled(!isEnabled);
  };

  $scope.toggleDisplaySums = function () {
    closeAnyContextMenu();
    wpTableSum.toggle();
  };

  $scope.showSettingsModalInvalid = function () {
    return !query.id || AuthorisationService.cannot('query', 'update');
  };

  $scope.showShareModalInvalid = function () {
    return (AuthorisationService.cannot('query', 'unstar') &&
    AuthorisationService.cannot('query', 'star'));
  };

  $scope.showExportModalInvalid = function () {
    return AuthorisationService.cannot('work_packages', 'representations');
  };

  $scope.deleteQueryInvalid = function () {
    return AuthorisationService.cannot('query', 'delete');
  };

  $scope.showSaveModalInvalid = function () {
    return AuthorisationService.cannot('query', 'updateImmediately');
  };

  $scope.saveQueryInvalid = function () {
    return AuthorisationService.cannot('query', 'updateImmediately');
  };

  function showModal(this:any) {
    closeAnyContextMenu();
    this.activate();
  }

  function showExistingQueryModal(this:any, event:JQueryEventObject) {
    closeAnyContextMenu();
    this.activate();
  }

  function allowQueryAction(event:JQueryEventObject, action:any) {
    return allowAction(event, 'query', action);
  }

  function allowWorkPackageAction(event:JQueryEventObject, action:any) {
    return allowAction(event, 'work_packages', action);
  }

  function allowFormAction(event:JQueryEventObject, action:string) {
    if (form.$links[action]) {
      return true;
    } else {
      event.stopPropagation();
      return false;
    }
  }

  function allowAction(event:JQueryEventObject, modelName:string, action:any) {
    if (AuthorisationService.can(modelName, action)) {
      return true;
    } else {
      event.stopPropagation();
      return false;
    }
  }

  function closeAnyContextMenu() {
    contextMenu.close();
  }

  function deleteConfirmed() {
    return $window.confirm(I18n.t('js.text_query_destroy_confirmation'));
  }

  function updateFocusInModal(element_id:string) {
    setTimeout(function () {
      jQuery('#' + element_id).focus();
    }, 100);
  }
}

opWorkPackagesModule.controller('SettingsDropdownMenuController', SettingsDropdownMenuController);
