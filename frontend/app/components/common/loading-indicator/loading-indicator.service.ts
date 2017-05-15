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

export const indicatorLocationSelector = '.loading-indicator--location';
export const indicatorBackgroundSelector = '.loading-indicator--background';


export class LoadingIndicator {

  constructor(public indicator:JQuery, public element:JQuery) {}

  public set promise(promise:ng.IPromise<any>) {
    this.start();
    promise.finally(() => {
      // Delay hiding the indicator a little bit.
      setTimeout(() => this.stop(), 25);
    });
  }

  public start() {
    this.indicator.prepend(this.element);
  }

  public stop() {
    this.element.remove();

  }
}

export class LoadingIndicatorService {

  private indicatorTemplate:string =
  `<div class="loading-indicator--background">
      <div class="loading-indicator">
        <div class="block-1"></div>
        <div class="block-2"></div>
        <div class="block-3"></div>
        <div class="block-4"></div>
        <div class="block-5"></div>
      </div>
    </div>
   `;

  // Provide shortcut to the primarily used indicators
  public get table() { return this.indicator('table'); }
  public get wpDetails() { return this.indicator('wpDetails'); }
  public get modal() { return this.indicator('modal'); }

  // Return an indicator by name
  public indicator(name:string):LoadingIndicator {
    let indicator = this.getIndicatorAt(name);
    return new LoadingIndicator(indicator, jQuery(this.indicatorTemplate));
  }

  private getIndicatorAt(name:string):JQuery {
    return jQuery(indicatorLocationSelector).filter(`[data-indicator-name="${name}"]`);
  }
}


import {opServicesModule} from '../../../angular-modules';
opServicesModule.service('loadingIndicator', LoadingIndicatorService);
