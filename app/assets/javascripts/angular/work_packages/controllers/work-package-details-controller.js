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

angular.module('openproject.workPackages.controllers')

.controller('WorkPackageDetailsController', [
  '$scope',
  'latestTab',
  'workPackage',
  'I18n',
  '$q',
  'ConfigurationService',
  function($scope, latestTab, workPackage, I18n,$q, ConfigurationService) {
    $scope.$on('$stateChangeSuccess', function(event, toState){
      latestTab.registerState(toState.name);
    });

    // initialization
    setWorkPackage(workPackage);
    $scope.I18n = I18n;
    $scope.$parent.preselectedWorkPackageId = $scope.workPackage.props.id;
    $scope.maxDescriptionLength = 800;

    function refreshWorkPackage() {
      workPackage.links.self
        .fetch({force: true})
        .then(setWorkPackage);
    }
    $scope.refreshWorkPackage = refreshWorkPackage; // expose to child controllers

    function setWorkPackage(workPackage) {
      $scope.workPackage = workPackage;
      $scope.isWatched = !!workPackage.links.unwatch;
      $scope.toggleWatchLink = workPackage.links.watch === undefined ? workPackage.links.unwatch : workPackage.links.watch;
      $scope.watchers = workPackage.embedded.watchers;
    }

    function outputError(error) {
      $scope.$emit('flashMessage', {
        isError: true,
        text: error.message
      });
    }
    $scope.outputError = outputError; // expose to child controllers

    $scope.toggleWatch = function() {
      $scope.toggleWatchLink
        .fetch({ ajax: $scope.toggleWatchLink.props })
        .then(refreshWorkPackage, outputError);
    };

    // resources for tabs

    $scope.author = workPackage.embedded.author;

    // activities and latest activities

    $scope.activities = workPackage.embedded.activities;
    $scope.activities.splice(0, 1); // remove first activity (assumes activities are sorted chronologically)

    $scope.latestActitivies = $scope.activities.reverse().slice(0, 3); // this leaves the activities in reverse order

    $scope.activitiesSortedInDescendingOrder = ConfigurationService.commentsSortedInDescendingOrder();

    // restore former order of actvities unless comments are to be sorted in descending order
    if (!$scope.activitiesSortedInDescendingOrder) {
      $scope.activities.reverse();
    }

    $scope.deleteWatcher = function(watcher) {
      watcher.links.removeWatcher
        .fetch({ ajax: watcher.links.removeWatcher.props })
        .then(refreshWorkPackage, outputError);
    };

    // Attachments
    $scope.attachments = workPackage.embedded.attachments;

    $scope.editWorkPackage = function() {
      // TODO: Temporarily going to the old edit dialog until we get in-place editing done
      window.location = "/work_packages/" + $scope.workPackage.props.id;
    };
  }
]);
