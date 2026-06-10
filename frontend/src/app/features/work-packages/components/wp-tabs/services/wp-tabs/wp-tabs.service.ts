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

import { Injectable, Injector, inject } from '@angular/core';
import { from } from 'rxjs';
import { StateService } from '@uirouter/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WpTabDefinition } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/tab';
import {
  WorkPackageRelationsTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/relations-tab/relations-tab.component';
import {
  WorkPackageOverviewTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/overview-tab/overview-tab.component';
import {
  WorkPackageActivityTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/activity-tab.component';
import {
  WorkPackageWatchersTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import {
  WorkPackageFilesTabComponent,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/files-tab/op-files-tab.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  workPackageWatchersCount,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-watchers-count.function';
import {
  workPackageRelationsCount,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-relations-count.function';
import {
  workPackageNotificationsCount,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-notifications-count.function';
import {
  workPackageFilesCount,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-files-count.function';

@Injectable({
  providedIn: 'root',
})
export class WorkPackageTabsService {
  private $state = inject(StateService);
  private I18n = inject(I18nService);
  private injector = inject(Injector);

  private registeredTabs:WpTabDefinition[];

  constructor() {
    this.registeredTabs = this.buildDefaultTabs();
  }

  get tabs():WpTabDefinition[] {
    return [...this.registeredTabs];
  }

  register(...tabs:WpTabDefinition[]):void {
    this.registeredTabs = [
      ...this.registeredTabs,
      ...tabs,
    ];
  }

  registerBefore(id:string, tab:WpTabDefinition):void {
    const index = this.registeredTabs.findIndex((t) => t.id === id);
    if (index !== -1) {
      this.registeredTabs.splice(index, 0, tab);
    } else {
      throw new Error(`Tab with id "${id}" not found. Appending tab to the end.`);
    }
  }

  registerAfter(id:string, tab:WpTabDefinition):void {
    const index = this.registeredTabs.findIndex((t) => t.id === id);
    if (index !== -1) {
      this.registeredTabs.splice(index + 1, 0, tab);
    } else {
      throw new Error(`Tab with id "${id}" not found. Appending tab to the end.`);
    }
  }


  patchTabCondition(id:string, displayable:(workPackage:WorkPackageResource, $state:StateService) => boolean):void {
    const tabDefinition = this.registeredTabs.find((tab) => tab.id === id);
    if (tabDefinition) {
      tabDefinition.displayable = displayable;
    }
  }

  getDisplayableTabs(workPackage:WorkPackageResource, routedFromAngular = true):WpTabDefinition[] {
    return this
      .tabs
      .filter(
        (tab) => !tab.displayable || tab.displayable(workPackage, routedFromAngular ? this.$state : null),
      )
      .map(
        (tab) => ({
          ...tab,
          counter: tab.count
            ? (injector:Injector) => tab.count!(workPackage, injector || this.injector)
            : (_:Injector) => from([0]),
        }),
      );
  }

  getTab(tabId:string, workPackage:WorkPackageResource):WpTabDefinition|undefined {
    return this.getDisplayableTabs(workPackage).find(({ id }) => id === tabId);
  }

  private buildDefaultTabs():WpTabDefinition[] {
    return [
      {
        component: WorkPackageOverviewTabComponent,
        name: this.I18n.t('js.work_packages.tabs.overview'),
        id: 'overview',
        displayable: (_, $state) => $state ? $state.includes('**.details.*') : false,
      },
      {
        id: 'activity',
        component: WorkPackageActivityTabComponent,
        name: I18n.t('js.work_packages.tabs.activity'),
        count: workPackageNotificationsCount,
        showCountAsBubble: true,
      },
      {
        id: 'files',
        component: WorkPackageFilesTabComponent,
        name: I18n.t('js.work_packages.tabs.files'),
        count: workPackageFilesCount,
      },
      {
        id: 'relations',
        component: WorkPackageRelationsTabComponent,
        name: I18n.t('js.work_packages.tabs.relations'),
        count: workPackageRelationsCount,
      },
      {
        id: 'watchers',
        component: WorkPackageWatchersTabComponent,
        name: I18n.t('js.work_packages.tabs.watchers'),
        displayable: (workPackage) => !!workPackage.watchers,
        count: workPackageWatchersCount,
      },
    ];
  }
}
