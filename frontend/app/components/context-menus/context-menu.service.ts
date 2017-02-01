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

interface ContextMenu {
  active();
  close();
  open();
  reposition();
}

export class ContextMenuService {
  private _active_menu:ContextMenu|null;

  constructor(public $window, public $injector, public $rootScope) {
    "ngInject";

    // Close context menus on state change
    $rootScope.$on('$stateChangeStart', () => this.close());

    // Listen to keyups on window to close context menus
    Mousetrap.bind('escape', () => this.close());

    // Listen to any click and close the active context menu
    jQuery($window).click(() => this.close());

  }

  // Return the active context menu, if any
  public get active():ContextMenu|null {
    return this._active_menu;
  }

  public close() {
    this.active && this.active.close();
  }

  public activate(contextMenuName, target:JQuery, locals) {
    let contextMenu = this.$injector.get(contextMenuName);

    // Close other context menu
    this.close();

    // Open the menu
    contextMenu.open(target, locals).then((menuElement) => {
      contextMenu.menuElement = menuElement;
      this._active_menu = contextMenu;
      this.reposition();
      (menuElement as any).trap();
      menuElement.on('click', function (e) {
        // allow inputs to be clickable
        // without closing the dropdown
        if (angular.element(e.target).is(':input')) {
          e.stopPropagation();
        }
      });
    });
  }

  public reposition() {
    if (!this.active) {
      return;
    }

    let menuElement = this.active.menuElement;
    let target = this.active.target;

    menuElement.position({ my: 'center', at: 'bottom right', of: target });
  }
}

angular
  .module('openproject.services')
  .service('contextMenu', ContextMenuService);
