//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, Injector } from '@angular/core';
import { StateService, Transition } from '@uirouter/core';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

export interface BackRouteOptions {
  name:string;
  params:{};
  parent:string;
  baseRoute:string;
}

@Injectable({ providedIn: 'root' })
export class BackRoutingService {
  @InjectField() private $state:StateService;

  @InjectField() private keepTab:KeepTabService;

  private _backRoute:BackRouteOptions;

  constructor(readonly injector:Injector) {
  }

  private goToOtherState(route:string, params:Record<string, unknown>):Promise<unknown> {
    return this.$state.go(route, params);
  }

  private goBackToDetailsState(preferListOverSplit:boolean, baseRoute:string):void {
    if (preferListOverSplit) {
      this.goToOtherState(baseRoute, this.backRoute.params);
    } else {
      const state = `${baseRoute}.details.tabs`;
      const params = { ...this.backRoute.params, tabIdentifier: this.keepTab.currentDetailsTab };
      this.goToOtherState(state, params);
    }
  }

  private goBackNotToDetailsState():void {
    if (this.backRoute.parent) {
      this.goToOtherState(this.backRoute.name, this.backRoute.params).then(() => {
        this.$state.reload();
      });
    } else {
      this.goToOtherState(this.backRoute.name, this.backRoute.params);
    }
  }

  private goBackToPreviousState(preferListOverSplit:boolean, baseRoute:string):void {
    if (this.keepTab.isDetailsState(this.backRoute.parent)) {
      this.goBackToDetailsState(preferListOverSplit, baseRoute);
    } else {
      this.goBackNotToDetailsState();
    }
  }

  public goBack(preferListOverSplit = false) {
    // Default: back to list
    // When coming from a deep link or a create form
    const baseRoute = this.backRoute?.baseRoute || this.$state.current.data.baseRoute || 'work-packages.partitioned.list';
    // if we are in the first state
    if (!this.backRoute && baseRoute.includes('show')) {
      this.$state.reload();
    } else if (!this.backRoute || this.backRoute.name.includes('new')) {
      this.$state.go(baseRoute, this.$state.params);
    } else {
      this.goBackToPreviousState(preferListOverSplit, baseRoute);
    }
  }

  public goToBaseState() {
    const baseRoute = this.$state.current.data.baseRoute || 'work-packages.partitioned.list';
    this.$state.go(baseRoute, this.$state.params);
  }

  public sync(transition:Transition) {
    const fromState = transition.from();
    const toState = transition.to();

    // Set backRoute to know where we came from
    if (fromState.name
      && fromState.data
      && toState.data
      && fromState.data.parent !== toState.data.parent) {
      const paramsFromCopy = { ...transition.params('from') };
      this.backRoute = {
        name: fromState.name,
        params: paramsFromCopy,
        parent: fromState.data.parent,
        baseRoute: fromState.data.baseRoute,
      };
    }
  }

  public set backRoute(route:BackRouteOptions) {
    this._backRoute = route;
  }

  public get backRoute():BackRouteOptions {
    return this._backRoute;
  }
}
