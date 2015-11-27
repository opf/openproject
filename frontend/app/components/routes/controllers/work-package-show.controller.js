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
  .module('openproject.workPackages.controllers')
  .controller('WorkPackageShowController', WorkPackageShowController);

function WorkPackageShowController($scope, $rootScope, $state, latestTab, workPackage, I18n,
    RELATION_TYPES, RELATION_IDENTIFIERS, $q, WorkPackagesHelper, PathHelper, UsersHelper,
    WorkPackageService, CommonRelationsHandler,
    ChildrenRelationsHandler, ParentRelationsHandler, WorkPackagesOverviewService,
    WorkPackageFieldService, EditableFieldsState, WorkPackagesDisplayHelper, NotificationsService,
    WorkPackageAuthorization, PERMITTED_MORE_MENU_ACTIONS, HookService, $window,
    WorkPackageAttachmentsService, AuthorisationService) {

  $scope.editAll = EditableFieldsState.editAll;

  $scope.$on('$stateChangeSuccess', function(event, toState){
    latestTab.registerState(toState.name);
  });

  // Listen to the event globally, as listeners are not necessarily
  // in the child scope
  $rootScope.$on('workPackageRefreshRequired', function() {
    refreshWorkPackage();
  });

  AuthorisationService.initModelAuth('work_package', workPackage.links);

  // initialization
  setWorkPackageScopeProperties(workPackage);

  // stuff copied from details toolbar directive...
  function getPermittedActions(authorization, permittedMoreMenuActions) {
    var permittedActions = authorization.permittedActions(permittedMoreMenuActions);
    var augmentedActions = { };

    angular.forEach(permittedActions, function(value, key) {
      var css = ['icon-' + key];

      this[key] = { link: value, css: css };
    }, augmentedActions);

    return augmentedActions;
  }
  function getPermittedPluginActions(authorization) {
    var pluginActions = HookService
                        .call('workPackageDetailsMoreMenu')
                        .reduce(function(previousValue, currentValue) {
                          return angular.extend(previousValue, currentValue);
                        }, { });

    var permittedPluginActions = authorization.permittedActions(Object.keys(pluginActions));
    var augmentedPluginActions = { };

    angular.forEach(permittedPluginActions, function(value, key) {
      var css = [].concat(pluginActions[key]);

      if (css.length === 0) {
        css = ['icon-' + key];
      }

      this[key] = { link: value, css: css };
    }, augmentedPluginActions);

    return augmentedPluginActions;
  }
  function deleteSelectedWorkPackage() {
    var promise = WorkPackageService.performBulkDelete([$scope.workPackage.props.id], true);

    promise.success(function() {
      $state.go('work-packages.list', {projectPath: $scope.projectIdentifier});
    });
  }
  $scope.triggerMoreMenuAction = function(action, link) {
    switch (action) {
      case 'delete':
        deleteSelectedWorkPackage();
        break;
      default:
        $window.location.href = link;
        break;
    }
  };
  var authorization = new WorkPackageAuthorization($scope.workPackage);
  $scope.permittedActions = angular.extend(getPermittedActions(authorization, PERMITTED_MORE_MENU_ACTIONS),
                                           getPermittedPluginActions(authorization));
  $scope.actionsAvailable = Object.keys($scope.permittedActions).length > 0;

  // END stuff copied from details toolbar directive...

  $scope.I18n = I18n;
  $scope.$parent.preselectedWorkPackageId = $scope.workPackage.props.id;
  $scope.maxDescriptionLength = 800;
  $scope.projectIdentifier = $scope.workPackage.embedded.project.props.identifier;


  function refreshWorkPackage() {
    WorkPackageService.getWorkPackage($scope.workPackage.props.id)
      .then(function(workPackage) {
        setWorkPackageScopeProperties(workPackage);
        $scope.$broadcast('workPackageRefreshed');
      });
  }

  // Inform parent that work package is loaded so back url can be maintained
  $scope.$emit('workPackgeLoaded');

  function outputMessage(message, isError) {
    $scope.$emit('flashMessage', {
      isError: !!isError,
      text: message
    });
  }

  function outputError(error) {
    outputMessage(error.message || I18n.t('js.work_packages.error'), true);
  }

  $scope.outputMessage = outputMessage; // expose to child controllers
  $scope.outputError = outputError; // expose to child controllers


  function setWorkPackageScopeProperties(workPackage){
    $scope.workPackage = workPackage;
    $scope.isWatched = workPackage.links.hasOwnProperty('unwatch');
    $scope.displayWatchButton = workPackage.links.hasOwnProperty('unwatch') ||
                                workPackage.links.hasOwnProperty('watch');

    // watchers
    if(workPackage.links.watchers) {
      $scope.watchers = workPackage.embedded.watchers.embedded.elements;
    }

    $scope.showStaticPagePath = PathHelper.staticWorkPackagePath($scope.workPackage.props.id);

    // Type
    $scope.type = workPackage.embedded.type;

    // Author
    $scope.author = workPackage.embedded.author;
    $scope.authorPath = PathHelper.staticUserPath($scope.author.props.id);
    $scope.authorActive = UsersHelper.isActive($scope.author);

    // Attachments
    $scope.attachments = workPackage.embedded.attachments.embedded.elements;

    // relations
    $q.all(WorkPackagesHelper.getParent(workPackage)).then(function(parents) {
      var relationsHandler = new ParentRelationsHandler(workPackage, parents, 'parent');
      $scope.wpParent = relationsHandler;
    });

    $q.all(WorkPackagesHelper.getChildren(workPackage)).then(function(children) {
      var relationsHandler = new ChildrenRelationsHandler(workPackage, children);
      $scope.wpChildren = relationsHandler;
    });

    function relationTypeIterator(key) {
      $q.all(WorkPackagesHelper.getRelationsOfType(
        workPackage,
        RELATION_TYPES[key])
      ).then(function(relations) {
        var relationsHandler = new CommonRelationsHandler(workPackage,
                                                          relations,
                                                          RELATION_IDENTIFIERS[key]);
        $scope[key] = relationsHandler;
      });
    }

    for (var key in RELATION_TYPES) {
      if (RELATION_TYPES.hasOwnProperty(key)) {
        relationTypeIterator(key);
      }
    }
  }

  $scope.toggleWatch = function() {
    // Toggle early to avoid delay.
    $scope.isWatched = !$scope.isWatched;
    WorkPackageService.toggleWatch($scope.workPackage)
                      .then(function() { refreshWorkPackage() }, outputError);
  };

  $scope.canViewWorkPackageWatchers = function() {
    return !!($scope.workPackage && $scope.workPackage.embedded.watchers !== undefined);
  };

  // toggles

  $scope.toggleStates = {
    hideFullDescription: true,
    hideAllAttributes: true
  };

  $scope.showWorkPackageDetails = function() {
    var queryProps = $state.params['query_props'];

    $state.go('work-packages.list.details.overview', {
      projectPath: $scope.projectIdentifier,
      workPackageId: $scope.workPackage.props.id,
      'query_props': queryProps
    });
  };

  $scope.closeShowView = function() {
    var queryProps = $state.params['query_props'];

    $state.go('work-packages.list', {
      projectPath: $scope.projectIdentifier,
      workPackageId: $scope.workPackage.props.id,
      'query_props': queryProps
    });
  };

  function getFocusAnchorLabel(tab, workPackage) {
    var tabLabel = I18n.t('js.work_packages.tabs.' + tab),
        params = {
          tab: tabLabel,
          type: workPackage.props.type,
          subject: workPackage.props.subject
        };

    return I18n.t('js.label_work_package_details_you_are_here', params);
  }

  $scope.focusAnchorLabel = getFocusAnchorLabel(
    $state.current.url.replace(/\//, ''),
    $scope.workPackage
  );

  // Stuff copied from DetailsTabOverviewController
  var vm = this;

  vm.groupedFields = [];
  vm.hideEmptyFields = true;
  vm.workPackage = $scope.workPackage;

  vm.isGroupHideable = WorkPackagesDisplayHelper.isGroupHideable;
  vm.isFieldHideable = WorkPackagesDisplayHelper.isFieldHideable;
  vm.getLabel = WorkPackagesDisplayHelper.getLabel;
  vm.isSpecified = WorkPackagesDisplayHelper.isSpecified;
  vm.hasNiceStar = WorkPackagesDisplayHelper.hasNiceStar;
  vm.showToggleButton = WorkPackagesDisplayHelper.showToggleButton;
  vm.filesExist = false;

  activate();

  WorkPackageAttachmentsService.hasAttachments(vm.workPackage).then(function(bool) {
    vm.filesExist = bool;
  });

  function activate() {
    EditableFieldsState.forcedEditState = false;
    $scope.$watch('workPackage.schema', function(schema) {
      if (schema) {
        WorkPackagesDisplayHelper.setFocus();
        vm.workPackage = $scope.workPackage;
      }
    });
    vm.groupedFields = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes();

    $scope.$watchCollection('vm.workPackage.form', function(form) {
      var schema = WorkPackageFieldService.getSchema(vm.workPackage);
      var otherGroup = _.find(vm.groupedFields, {groupName: 'other'});
      otherGroup.attributes = [];
      _.forEach(schema.props, function(prop, propName) {
        if (propName.match(/^customField/)) {
          otherGroup.attributes.push(propName);
        }
      });
      otherGroup.attributes.sort(function(a, b) {
        var getLabel = function(field) {
          return vm.getLabel(vm.workPackage, field);
        };
        var left = getLabel(a).toLowerCase(),
            right = getLabel(b).toLowerCase();
        return left.localeCompare(right);
      });
    });
    $scope.$on('workPackageUpdatedInEditor', function() {
      NotificationsService.addSuccess(I18n.t('js.label_successful_update'));
    });
  }
}
