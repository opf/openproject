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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Injector } from '@angular/core';
import { GonService } from 'core-app/core/gon/gon.service';
import { StateService } from '@uirouter/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ScrollableTabsComponent } from 'core-app/shared/components/tabs/scrollable-tabs/scrollable-tabs.component';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';


interface GonTab extends TabDefinition {
  partial:string;
  label:string;
}

@Component({
  selector: 'opce-content-tabs',
  templateUrl: '../scrollable-tabs/scrollable-tabs.component.html',
  styleUrls: ['./content-tabs.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})

export class ContentTabsComponent extends ScrollableTabsComponent {
  public classes:string[] = ['content--tabs', 'scrollable-tabs'];

  constructor(
    readonly elementRef:ElementRef,
    protected readonly $state:StateService,
    readonly gon:GonService,
    cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    public injector:Injector,
  ) {
    super($state, cdRef, injector);

    const gonTabs = JSON.parse((this.gon.get('contentTabs') as any).tabs);
    const currentTab = JSON.parse((this.gon.get('contentTabs') as any).selected);

    // parse tabs from backend and map them to scrollable tabs structure
    this.tabs = gonTabs.map((tab:GonTab) => ({
      id: tab.name,
      name: this.I18n.t(`js.${tab.label}`, { defaultValue: tab.label }),
      path: tab.path,
    }));

    // highlight current tab
    this.currentTabId = currentTab.name;
  }
}
