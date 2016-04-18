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

export interface PanelNavRoutes {
  [route: string]: PanelNavRoute;
}

export interface PanelNavItem {
  route:string;
  text:string;
  show?:boolean;
  activeTitle?:string;
}

class PanelNavRoute {
  private _items:PanelNavItem[] = [];

  public get items():PanelNavItem[] {
    return this._items;
  }

  public addItem(item:PanelNavItem):PanelNavRoute {
    var defaultItem:PanelNavItem = {
      route: '',
      text: '',
      show: true
    };

    angular.extend(defaultItem, item);
    this.items.push(defaultItem);

    return this;
  }

  public getItem(route:string):PanelNavItem {
    return _.find(this.items, {route: route});
  }
}

export class PanelNavService {
  protected routes:PanelNavRoutes = {};

  public route(route:string):PanelNavRoute {
    if (!this.routes[route]) {
      this.routes[route] = new PanelNavRoute();
    }

    return this.routes[route];
  }
}

angular
  .module('openproject')
  .service('panelNavService', PanelNavService);
