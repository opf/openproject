// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { ChangeDetectorRef, Component, OnDestroy } from '@angular/core';
import { Subscription } from 'rxjs';
import { GlobalSearchService } from 'core-app/core/global_search/services/global-search.service';
import { ScrollableTabsComponent } from 'core-app/shared/components/tabs/scrollable-tabs/scrollable-tabs.component';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';

export const globalSearchTabsSelector = 'global-search-tabs';

@Component({
  selector: globalSearchTabsSelector,
  templateUrl: '../../../shared/components/tabs/scrollable-tabs/scrollable-tabs.component.html',
})

export class GlobalSearchTabsComponent extends ScrollableTabsComponent implements OnDestroy {
  private currentTabSub:Subscription;

  private tabsSub:Subscription;

  public classes:string[] = ['global-search--tabs', 'scrollable-tabs'];

  constructor(readonly globalSearchService:GlobalSearchService,
    cdRef:ChangeDetectorRef) {
    super(cdRef);
  }

  ngOnInit() {
    this.currentTabSub = this.globalSearchService
      .currentTab$
      .subscribe((currentTab) => {
        this.currentTabId = currentTab;
      });

    this.tabsSub = this.globalSearchService
      .tabs$
      .subscribe((tabs) => {
        this.tabs = tabs;
        this.tabs.map((tab) => (tab.path = '#'));
      });
  }

  public clickTab(tab:TabDefinition, event:Event) {
    super.clickTab(tab, event);

    this.globalSearchService.currentTab = tab.id;
    this.globalSearchService.submitSearch();
  }

  ngOnDestroy():void {
    this.currentTabSub.unsubscribe();
    this.tabsSub.unsubscribe();
  }
}
