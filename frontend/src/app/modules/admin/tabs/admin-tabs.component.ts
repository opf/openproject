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

import {
  Component,
  OnDestroy,
  Input,
  ElementRef
} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {GonService} from "core-app/modules/common/gon/gon.service";
import {StateService} from '@uirouter/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ScrollableTabsComponent} from "core-app/modules/common/tabs/scrollable-tabs.component";


export const adminTabsSelector = 'admin-tabs';

interface Tab {
  name:string;
  partial:string;
  label:string;
}

@Component({
  selector: adminTabsSelector,
  templateUrl: '/app/modules/common/tabs/scrollable-tabs.component.html'
})

export class AdminTabsComponent extends ScrollableTabsComponent {
  public myTabs:Tab[] = [];
  public currentTab:Tab;

  public classes:string[] = ['admin--tabs', 'scrollable-tabs'];

  private gonData:any = this.gon.get('admin_tabs');

  constructor(readonly elementRef:ElementRef,
              readonly $state:StateService,
              readonly gon:GonService,
              readonly I18n:I18nService) {
    super();
    // parse tabs from backend and map them to scrollable tabs structure
    this.myTabs = jQuery.parseJSON(this.gonData.tabs);
    this.tabs = jQuery.map(this.myTabs, (tab:Tab) => {
      return {
        id: tab.name,
        name: this.I18n.t('js.' + tab.label)
      };
    });

    // highlight current tab
    this.currentTab = jQuery.parseJSON(this.gonData.selected);
    this.currentTabId = this.currentTab.name;
  }

  public clickTab(tab:string) {
    // set selected tab as current
    this.currentTab = jQuery.grep(this.myTabs, thisTab => thisTab.name === tab)[0];

    // set correct partial for selected tab
    this.partial = window.location.pathname + '?tab=' + this.currentTab.name;

    super.clickTab(tab);
  }
}

DynamicBootstrapper.register({
  selector: adminTabsSelector, cls: AdminTabsComponent
});
