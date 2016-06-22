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

export class KeepTabService {
  protected showTab:string = 'work-packages.show.activity';
  protected detailsTab:string = 'work-packages.list.details.overview';

  protected subject = new Rx.ReplaySubject<{ [tab: string]: string; }>(1);

  constructor(public $state:ng.ui.IStateService, protected $rootScope:ng.IRootScopeService) {
    'ngInject';

    this.updateTabs();
    $rootScope.$on('$stateChangeSuccess', () => {
      this.updateTabs();
    });
  }

  public get observable() {
    return this.subject;
  }

  public get currentShowTab():string {
    return this.showTab;
  }

  public get currentDetailsTab():string {
    return this.detailsTab;
  }

  public get currentTabs():{ [tab: string]: string; } {
    return {
      show: this.showTab,
      details: this.detailsTab
    }
  }

  protected updateTab(stateName:string, tabName:string) {
    this[tabName] = this.$state.includes(stateName) ? this.$state.current.name : this[tabName];
  }

  protected updateTabs() {
    this.updateTab('work-packages.show.*', 'showTab');
    this.updateTab('work-packages.list.details.*', 'detailsTab');

    this.subject.onNext(this.currentTabs);
  }
}

angular
  .module('openproject.workPackages.services')
  .service('keepTab', KeepTabService);
