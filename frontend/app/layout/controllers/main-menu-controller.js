//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See docs/COPYRIGHT.rdoc for more details.
//++

module.exports = function($rootScope, $window) {
  var self = this;

  this.toggleNavigation = function(event) {
    event.preventDefault();
    event.stopPropagation();

    if (!$rootScope.showNavigation) {
      // main menu shall expand.

      // Set focus on first visible main menu item.
      //
      // This needs to be called after AngularJS has rendered the menu, which happens some when after(!) we leave this
      // method here. So we need to set the focus after a timeout.
      setTimeout(function() {
        jQuery('#main-menu [class*="-menu-item"]:visible').first().focus();
      }, 100);

      // On mobile the main menu shall close whenever you click outside the menu.
      if ($window.innerWidth < 680) {
        self.setupAutocloseMainMenu();
      }

      // Regain default width: Expand to default menu width if collapsed slimmer than default width.
      var savedMainMenuWidth = parseInt(window.OpenProject.guardedLocalStorage("openProject-mainMenuWidth"));
      if (savedMainMenuWidth < 230) {
        document.documentElement.style.setProperty("--main-menu-width", '230px');
        window.OpenProject.guardedLocalStorage("openProject-mainMenuWidth", '230');
      }
    }
    $rootScope.showNavigation = !$rootScope.showNavigation;

    $rootScope.$broadcast('openproject.layout.navigationToggled', $rootScope.showNavigation);
    $window.sessionStorage.setItem('openproject:navigation-toggle',
      !$rootScope.showNavigation ? 'collapsed' : 'expanded');
  };

  this.setupAutocloseMainMenu = function() {
    jQuery('#main-menu').off('focusout.main_menu');
    jQuery('#main-menu').on('focusout.main_menu', function (event) {
      // Check that main menu is not closed and that the `focusout` event is not a click on an element that tries to close
      // the menu anyways.
      if (!$rootScope.showNavigation ||
          jQuery.contains(document.getElementById('main-menu-toggle'), event.relatedTarget)) {
        return;
      }

      // There might be a time gap between `focusout` and the focussing of the activeElement, thus we need a timeout.
      setTimeout(function() {
        if (!jQuery.contains(document.getElementById('main-menu'), document.activeElement)) {
          // activeElement is outside of main menu.
          self.toggleNavigation(new Event('onclick'));
        }
      }, 0);
    });
  }
};
