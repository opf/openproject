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

import {ReplaySubject} from "rxjs";
export class KeepTabService {
  protected currentTab:string = 'overview';

  protected subject = new ReplaySubject<{ [tab: string]: string; }>(1);

  constructor(public $state:ng.ui.IStateService, protected $rootScope:ng.IRootScopeService) {
    'ngInject';

    this.updateTabs();
    $rootScope.$on('$stateChangeSuccess', (_event, toState) => {
      this.updateTabs(toState);
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

  public get currentShowState():string {
    return 'work-packages.show.' + this.currentShowTab;
  }

  public get currentDetailsState():string {
    return 'work-packages.list.details.' + this.currentDetailsTab;
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

  protected notify() {
    // Notify when updated
    this.subject.next({
      active: this.lastActiveTab,
      show: this.currentShowState,
      details: this.currentDetailsState
    });
  }

  protected updateTab(stateName:string) {
    if (this.isCurrentState(stateName)) {
      const current = this.$state.current.name as string;
      this.currentTab = (current.split('.') as any[]).pop();

      this.notify();
    }
  }

  protected isCurrentState(stateName:string):boolean {
    if (stateName === 'show') {
      return this.$state.includes('work-packages.show.*');
    }

    if (stateName === 'details') {
      return this.$state.includes('work-packages.list.details.*');
    }

    return false;
  }

  protected updateTabs(toState?:any) {

    // Ignore the switch from show#activity to details#activity
    // and show details#overview instead

    if (toState && toState.name === 'work-packages.show.activity') {
      this.currentTab = 'overview';
      return this.notify();
    }

    this.updateTab('show');
    this.updateTab('details');
  }
}

angular
  .module('openproject.workPackages.services')
  .service('keepTab', KeepTabService);
