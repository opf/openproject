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

module.exports = function($scope,
    $state,
    latestTab,
    workPackage,
    I18n,
    RELATION_TYPES,
    RELATION_IDENTIFIERS,
    $q,
    WorkPackagesHelper,
    PathHelper,
    UsersHelper,
    ConfigurationService,
    WorkPackageService,
    CommonRelationsHandler,
    ChildrenRelationsHandler,
    ParentRelationsHandler
  ) {
  $scope.$on('$stateChangeSuccess', function(event, toState){
    latestTab.registerState(toState.name);
  });

  $scope.$on('workPackageRefreshRequired', function(e, callback) {
    refreshWorkPackage(callback);
  });

  // initialization
  setWorkPackageScopeProperties(workPackage);

  $scope.I18n = I18n;
  $scope.$parent.preselectedWorkPackageId = $scope.workPackage.props.id;
  $scope.maxDescriptionLength = 800;

  function refreshWorkPackage(callback) {
    WorkPackageService.getWorkPackage($scope.workPackage.props.id)
      .then(function(workPackage) {
        setWorkPackageScopeProperties(workPackage);
        $scope.$broadcast('workPackageRefreshed');
        if (callback) {
          callback(workPackage);
        }
      });
  }
  $scope.refreshWorkPackage = refreshWorkPackage; // expose to child controllers

  // Inform parent that work package is loaded so back url can be maintained
  $scope.$emit('workPackgeLoaded');

  function outputMessage(message, isError) {
    $scope.$emit('flashMessage', {
      isError: !!isError,
      text: message
    });
  }

  function outputError(error) {
    outputMessage(error.message, true);
  }

  $scope.outputMessage = outputMessage; // expose to child controllers
  $scope.outputError = outputError; // expose to child controllers

  function setWorkPackageScopeProperties(workPackage){
    $scope.workPackage = workPackage;
    $scope.isWatched = !!workPackage.links.unwatch;

    if (workPackage.links.watch === undefined) {
      $scope.toggleWatchLink = workPackage.links.unwatch;
    } else {
      $scope.toggleWatchLink = workPackage.links.watch;
    }

    // autocomplete path
    var projectId = workPackage.embedded.project.props.id;
    $scope.autocompletePath = PathHelper.staticWorkPackagesAutocompletePath(projectId);

    // activities and latest activities
    $scope.activitiesSortedInDescendingOrder = ConfigurationService.commentsSortedInDescendingOrder();
    $scope.activities = displayedActivities($scope.workPackage);

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
    var fetchOptions = {
      method: $scope.toggleWatchLink.props.method
    };

    if($scope.toggleWatchLink.props.payload !== undefined) {
      fetchOptions.contentType = 'application/json; charset=utf-8';
      fetchOptions.data = JSON.stringify($scope.toggleWatchLink.props.payload);
    }

    $scope.toggleWatchLink
      .fetch({ajax: fetchOptions})
      .then(refreshWorkPackage, outputError);
  };

  $scope.canViewWorkPackageWatchers = function() {
    return !!($scope.workPackage && $scope.workPackage.embedded.watchers !== undefined);
  };

  function displayedActivities(workPackage) {
    var activities = workPackage.embedded.activities;
    // remove first activity (assumes activities are sorted chronologically)
    activities.splice(0, 1);
    if ($scope.activitiesSortedInDescendingOrder) {
      activities.reverse();
    }
    return activities;
  }

  // toggles

  $scope.toggleStates = {
    hideFullDescription: true,
    hideAllAttributes: true
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
};
