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

import {
  StateService, Transition, TransitionService, UIRouterGlobals,
} from '@uirouter/core';
import { ReplaySubject } from 'rxjs';
import { Injectable } from '@angular/core';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';

@Injectable({ providedIn: 'root' })
export class KeepTabService {
  protected currentTab = 'overview';

  protected subject = new ReplaySubject<{ [tab:string]:string; }>(1);

  constructor(protected $state:StateService,
    protected uiRouterGlobals:UIRouterGlobals,
    protected $transitions:TransitionService) {
    this.updateTabs();
    $transitions.onSuccess({}, (transition:Transition) => {
      this.updateTabs(transition.params('to').tabIdentifier);
    });
  }

  public get observable() {
    return this.subject;
  }

  /**
   * Return the last active tab.
   */
  public get lastActiveTab():string {
    if (this.isCurrentState('show')) {
      return this.currentShowTab;
    }

    return this.currentDetailsTab;
  }

  public goCurrentShowState(params:Record<string, unknown> = {}):void {
    this.$state.go(
      'work-packages.show.tabs',
      {
        ...this.uiRouterGlobals.params,
        ...params,
        tabIdentifier: this.currentShowTab,
      },
    );
  }

  public goCurrentDetailsState(params:Record<string, unknown> = {}):void {
    const route = splitViewRoute(this.$state);

    this.$state.go(
      `${route}.tabs`,
      {
        ...this.uiRouterGlobals.params,
        ...params,
        tabIdentifier: this.currentDetailsTab,
      },
    );
  }

  public isDetailsState(stateName:string):boolean {
    return !!stateName && stateName.includes('.details');
  }

  public get currentShowTab():string {
    // Show view doesn't have overview
    // use activity instead
    if (this.currentTab === 'overview') {
      return 'activity';
    }

    return this.currentTab;
  }

  public get currentDetailsTab():string {
    return this.currentTab;
  }

  get currentTabIdentifier():string|undefined {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return
    return this.uiRouterGlobals.params.tabIdentifier;
  }

  protected notify() {
    // Notify when updated
    this.subject.next({
      active: this.lastActiveTab,
      show: this.currentShowTab,
      details: this.currentDetailsTab,
    });
  }

  protected updateTab(stateName:string) {
    if (this.isCurrentState(stateName)) {
      this.currentTab = this.uiRouterGlobals.params.tabIdentifier;

      this.notify();
    }
  }

  protected isCurrentState(stateName:string):boolean {
    if (stateName === 'show') {
      return this.$state.includes('work-packages.show.*');
    }
    if (stateName === 'details') {
      return this.$state.includes('**.details.*');
    }

    return false;
  }

  public updateTabs(currentTab?:string) {
    // Ignore the switch from show#activity to details#activity
    // and show details#overview instead
    if (this.isCurrentState('show') && currentTab === 'activity') {
      this.currentTab = 'overview';
      return this.notify();
    }
    this.updateTab('show');
    this.updateTab('details');
  }
}
