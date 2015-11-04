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

module.exports = function(I18n, WorkPackageService) {
  'use strict';

  var workPackageWatcherButtonController = function(scope) {
    var workPackage = scope.workPackage;

    scope.isWatched = workPackage.links.hasOwnProperty('unwatch');
    scope.displayWatchButton = workPackage.links.hasOwnProperty('unwatch') ||
      workPackage.links.hasOwnProperty('watch');


    scope.toggleWatch = function() {
      // Toggle early to avoid delay.
      scope.isWatched = !scope.isWatched;

      setWatchStatus();

      WorkPackageService.toggleWatch(scope.workPackage)
        .then(function() {
          scope.$emit('workPackageRefreshRequired');
        });
    };


    function setWatchStatus() {
      if (scope.isWatched) {
        scope.buttonTitle = I18n.t('js.label_unwatch_work_package');
        scope.buttonText = I18n.t('js.label_unwatch');
        scope.buttonId = 'unwatch-button';
        scope.watchIconClass = 'icon-watch-1';
      } else {
        scope.buttonTitle = I18n.t('js.label_watch_work_package');
        scope.buttonText = I18n.t('js.label_watch');
        scope.buttonId = 'watch-button';
        scope.watchIconClass = 'icon-not-watch';
      }
    }

    // Set initial status
    setWatchStatus();

  };

  return {
    replace: true,
    templateUrl: '/templates/work_packages/watcher_button.html',
    link: workPackageWatcherButtonController,
    scope: {
      workPackage: '=',
      showText: '='
    }
  };
};
