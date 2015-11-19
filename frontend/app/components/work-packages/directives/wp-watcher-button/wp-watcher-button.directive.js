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
  .module('openproject.workPackages.directives')
  .directive('wpWatcherButton', wpWatcherButton);

function wpWatcherButton() {
  return {
    replace: true,
    templateUrl: '/components/work-packages/directives/wp-watcher-button/' +
      'wp-watcher-button.directive.html',

    scope: {
      workPackage: '=',
      showText: '=',
      disabled: '='
    },

    bindToController: true,
    controller: WorkPackageWatcherButtonController,
    controllerAs: 'vm'
  };
}

function WorkPackageWatcherButtonController($scope, WorkPackageService) {
  var vm = this,
      workPackage = vm.workPackage;

  vm.isWatched = workPackage.links.hasOwnProperty('unwatch');
  vm.displayWatchButton = workPackage.links.hasOwnProperty('unwatch') ||
    workPackage.links.hasOwnProperty('watch');


  vm.toggleWatch = function() {
    vm.isWatched = !vm.isWatched;

    setWatchStatus();

    WorkPackageService.toggleWatch(vm.workPackage).then(function() {
      $scope.$emit('workPackageRefreshRequired');
    });
  };


  function setWatchStatus() {
    if (vm.isWatched) {
      vm.buttonTitle = I18n.t('js.label_unwatch_work_package');
      vm.buttonText = I18n.t('js.label_unwatch');
      vm.buttonClass = '-active';
      vm.buttonId = 'unwatch-button';
      vm.watchIconClass = 'icon-watch-1';

    } else {
      vm.buttonTitle = I18n.t('js.label_watch_work_package');
      vm.buttonText = I18n.t('js.label_watch');
      vm.buttonClass = '';
      vm.buttonId = 'watch-button';
      vm.watchIconClass = 'icon-not-watch';
    }
  }

  setWatchStatus();
}
