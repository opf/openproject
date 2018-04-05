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
  var downToggler = null;

  this.toggleNavigation = function() {
    if ($rootScope.showNavigation) {
      downToggler = hideSubMenuEntries();
    } else {
      showSubMenuEntries(downToggler);
    }
    $rootScope.showNavigation = !$rootScope.showNavigation;
    $rootScope.$broadcast('openproject.layout.navigationToggled', $rootScope.showNavigation);
    $window.sessionStorage.setItem('openproject:navigation-toggle',
      !$rootScope.showNavigation ? 'collapsed' : 'expanded');
  };
};

function hideSubMenuEntries() {
  var upToggler = jQuery('ul.menu_root.closed > li.open .arrow-left-to-project');
  var downToggler = null;
  if (upToggler.length > 0) {
    downToggler = upToggler.parents('li.open').first().find('a.toggler');
    upToggler.trigger('click');
  }

  return downToggler;
}

function showSubMenuEntries(downToggler) {
  if (downToggler !== null) {
    downToggler.trigger('click');
  }
}
