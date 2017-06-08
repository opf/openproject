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
  close(disableFocus?:boolean):Promise<void>;
  open(nextTo:JQuery,locals:Object):Promise<JQuery>;

  target?:JQuery;
  menuElement:JQuery;
}

export class ContextMenuService {
  private active_menu:ContextMenu|null;
  private repositionCurrentElement:Function|null;

  constructor(public $window:ng.IWindowService,
              public $injector:ng.auto.IInjectorService,
              public $q:ng.IQService,
              public $timeout:ng.ITimeoutService,
              public $rootScope:ng.IRootScopeService) {
    "ngInject";

    // Close context menus on state change
    $rootScope.$on('$stateChangeStart', () => this.close());

    $rootScope.$on('repositionDropdown', () => {
      this.repositionCurrentElement && this.repositionCurrentElement();
    });

    // Listen to keyups on window to close context menus
    Mousetrap.bind('escape', () => this.close());

    // Listen to any click and close the active context menu
    jQuery($window).click(() => this.close());

  }

  // Return the active context menu, if any
  public get active():ContextMenu|null {
    return this.active_menu;
  }

  public close(disableFocus:boolean = false):Promise<void> {
    this.repositionCurrentElement = null;

    if (!this.active) {
      return this.$q.when(undefined);
    } else {
      return this.active.close(disableFocus);
    }
  }

  public activate(contextMenuName:string, event:Event, locals:Object, positionArgs?:any) {
    let deferred = this.$q.defer();
    let target = jQuery(event.target);
    let contextMenu:ContextMenu = <ContextMenu> this.$injector.get(contextMenuName);

    // Close other context menu
    this.close();

    // Open the menu
    contextMenu.open(target, locals).then((menuElement) => {

      contextMenu.menuElement = menuElement;
      this.active_menu = contextMenu;
      (menuElement as any).trap();
      menuElement.on('click', (evt) => {
        // allow inputs to be clickable
        // without closing the dropdown
        if (angular.element(evt.target).is(':input')) {
          evt.stopPropagation();
        }
      });

      this.repositionCurrentElement = () => this.reposition(event, positionArgs);

      this.$timeout(() => {
        this.repositionCurrentElement!();
        menuElement.css('visibility', 'visible');
        deferred.resolve(menuElement);
      });
    });

    return deferred.promise;
  }

  public reposition(event:Event, positionArgs?:Object) {
    if (!this.active) {
      return;
    }
    let position = { my: 'left top', at: 'right bottom', of: event, collision: 'flipfit' };
    _.assign(position, positionArgs);

    this.active.menuElement.position(position);
  }
}

angular
  .module('openproject.services')
  .service('contextMenu', ContextMenuService);
